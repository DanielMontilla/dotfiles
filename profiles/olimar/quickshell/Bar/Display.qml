import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".." as Root
import "../Components" as Components

Item {
  id: root
  property var panelWindow
  property var bar

  property bool menuOpen: false
  property bool popupVisible: false

  readonly property int autoHideDelay: 2000

  readonly property string deviceFlag: Root.Config.backlightDevice ? (" -d " + Root.Config.backlightDevice) : ""

  property bool initialized: false

  // Debounced slider pending value (local per-instance debounce buffer)
  property int pendingDebouncedBrightness: -1

  property bool readingGains: false

  // --- DDC detection ---
  Process {
    id: ddcDetect
    command: ["sh", "-c", "ddcutil detect 2>/dev/null | grep -oE '/dev/i2c-[0-9]+' | sed 's|/dev/i2c-||' | tr '\\n' ' '; echo"]
    stdout: StdioCollector {
      onStreamFinished: {
        const raw = text.trim().split(/\s+/).filter(b => b.length > 0).map(b => parseInt(b))
        const buses = raw.filter((b, i) => raw.indexOf(b) === i)
        if (buses.length > 0) {
          Root.Config.ddcBuses = buses
          Root.Config.brightnessBackend = "ddc"
          pollProcess.running = true
        } else {
          backlightDetect.running = true
        }
      }
    }
  }

  Process {
    id: backlightDetect
    command: ["sh", "-c", 'best=""; bestmax=0; for d in /sys/class/backlight/*/; do [ -e "$d/max_brightness" ] || continue; m=$(cat "$d/max_brightness" 2>/dev/null); case "$m" in (*[!0-9]*)) continue;; esac; if [ "$m" -gt "$bestmax" ]; then bestmax=$m; best=$(basename "$d"); fi; done; echo "$best"']
    stdout: StdioCollector {
      onStreamFinished: {
        const dev = text.trim()
        if (dev.length > 0) Root.Config.backlightDevice = dev
        Root.Config.brightnessBackend = "backlight"
        pollProcess.running = true
      }
    }
  }

  // --- Brightness polling ---
  // For DDC: reads each bus and reports per-bus current/max so we track
  // per-monitor max values for correct DDC writes.
  Process {
    id: pollProcess
    command: Root.Config.brightnessBackend === "ddc"
      ? ddcPollCommand()
      : ["sh", "-c", "echo $(brightnessctl" + deviceFlag + " get) $(brightnessctl" + deviceFlag + " max)"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (Root.Config.brightnessBackend === "ddc") {
          ddcPollFinished(text)
        } else {
          const parts = text.trim().split(/\s+/)
          if (parts.length === 2) {
            const current = parseInt(parts[0])
            const max = parseInt(parts[1])
            if (!isNaN(current) && !isNaN(max) && max > 0) {
              applyBrightnessReading(Math.round((current / max) * 100))
            }
          }
        }
      }
    }
    onExited: {
      if (!running) restartTimer.start()
    }
  }

  function ddcPollCommand(): var {
    const buses = Root.Config.ddcBuses
    if (buses.length === 0) return ["true"]
    const parts = []
    for (let i = 0; i < buses.length; i++) {
      const b = buses[i]
      parts.push("echo \"BUS=" + b + "\"")
      parts.push("timeout 2 ddcutil --bus " + b + " getvcp 10 2>/dev/null")
    }
    return ["sh", "-c", parts.join("; ")]
  }

  function ddcPollFinished(text: string) {
    const lines = text.trim().split("\n")
    let currentBus = -1
    let foundAny = false
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i]
      const busMatch = line.match(/^BUS=(\d+)$/)
      if (busMatch) {
        currentBus = parseInt(busMatch[1])
        continue
      }
      if (currentBus < 0) continue
      const cur = line.match(/current value\s*=\s*(\d+)/)
      const mx = line.match(/max value\s*=\s*(\d+)/)
      if (cur && mx) {
        const current = parseInt(cur[1])
        const max = parseInt(mx[1])
        if (max > 0) {
          Root.Config.brightnessMaxByBus[currentBus] = max
          if (!foundAny) {
            foundAny = true
            applyBrightnessReading(Math.round((current / max) * 100))
          }
        }
      }
    }
  }

  function applyBrightnessReading(newPercent: int) {
    if (!initialized) {
      initialized = true
      Root.Config.brightnessPercent = newPercent
      Root.Config.previousBrightnessPercent = newPercent
      return
    }
    if (Root.Config.brightnessSettingInFlight) {
      Root.Config.previousBrightnessPercent = newPercent
      return
    }
    if (newPercent !== Root.Config.brightnessPercent) {
      Root.Config.brightnessPercent = newPercent
      if (newPercent !== Root.Config.previousBrightnessPercent) {
        Root.Config.previousBrightnessPercent = newPercent
        showTemporarily()
      }
    }
  }

  Timer {
    id: restartTimer
    interval: Root.Config.brightnessBackend === "ddc" ? 1500 : 100
    onTriggered: pollProcess.running = true
  }

  Component.onCompleted: ddcDetect.running = true


  function showTemporarily() {
    if (bar.screen.name != Root.Config.focusedScreenName) return
    if (!menuOpen) bar.closeAllMenus()
    menuOpen = true
    autoHideTimer.restart()
  }

  // --- Serialized brightness write ---
  Process {
    id: brightnessSetProcess
    property int targetValue: 0

    onExited: {
      setWatchdog.stop()
      Root.Config.brightnessSettingInFlight = false
      resyncTimer.start()
      if (Root.Config.pendingBrightness >= 0 && Root.Config.pendingBrightness !== targetValue) {
        applyBrightnessSet(Root.Config.pendingBrightness)
      } else {
        Root.Config.pendingBrightness = -1
      }
    }
  }

  function applyBrightnessSet(percent: int) {
    percent = Math.max(0, Math.min(100, Math.round(percent)))
    brightnessSetProcess.targetValue = percent
    Root.Config.pendingBrightness = -1
    pendingDebouncedBrightness = -1
    Root.Config.brightnessSettingInFlight = true
    if (Root.Config.brightnessBackend === "ddc") {
      const buses = Root.Config.ddcBuses
      const cmds = []
      for (let i = 0; i < buses.length; i++) {
        const b = buses[i]
        const m = Root.Config.brightnessMaxByBus[b] || 100
        const value = Math.round((percent / 100) * m)
        // Run sequentially (not parallel) to avoid I2C lock contention
        cmds.push("timeout 3 ddcutil --sleep-multiplier 0.3 --bus " + b + " setvcp 10 " + value)
      }
      brightnessSetProcess.command = ["sh", "-c", cmds.join("; ")]
    } else {
      const args = ["brightnessctl"]
      if (Root.Config.backlightDevice) args.push("-d", Root.Config.backlightDevice)
      args.push("set", percent + "%")
      brightnessSetProcess.command = args
    }
    brightnessSetProcess.running = true
    setWatchdog.restart()
  }

  function setBrightness(percent: int) {
    percent = Math.max(0, Math.min(100, Math.round(percent)))
    Root.Config.brightnessPercent = percent
    Root.Config.previousBrightnessPercent = percent
    if (Root.Config.brightnessSettingInFlight) {
      Root.Config.pendingBrightness = percent
    } else {
      applyBrightnessSet(percent)
    }
  }

  function scheduleBrightness(percent: int) {
    pendingDebouncedBrightness = Math.max(0, Math.min(100, Math.round(percent)))
    brightnessDebounce.restart()
  }

  Timer {
    id: brightnessDebounce
    interval: 150
    onTriggered: {
      if (pendingDebouncedBrightness >= 0) {
        setBrightness(pendingDebouncedBrightness)
        pendingDebouncedBrightness = -1
      }
    }
  }

  Timer {
    id: resyncTimer
    interval: 500
    onTriggered: {
      if (!pollProcess.running) pollProcess.running = true
    }
  }

  Timer {
    id: setWatchdog
    interval: 15000
    onTriggered: {
      if (Root.Config.brightnessSettingInFlight) {
        brightnessSetProcess.running = false
        Root.Config.brightnessSettingInFlight = false
        Root.Config.pendingBrightness = -1
        pendingDebouncedBrightness = -1
        resyncTimer.start()
      }
    }
  }

  function adjustBrightness(normDelta: real) {
    setBrightness(Root.Config.brightnessPercent + normDelta * 100)
    showTemporarily()
  }

  function presetBrightness(pct: int) {
    setBrightness(pct)
    showTemporarily()
  }

  // --- Warmth via DDC video gain ---
  Process {
    id: warmthProcess
    stdout: StdioCollector {
      onStreamFinished: {
        if (readingGains) {
          parseGains(text)
          readingGains = false
          Root.Config.gainsLoaded = true
          if (Root.Config.warmthEnabled) applyWarmthSet()
        }
      }
    }
  }

  function parseGains(output: string) {
    const lines = output.trim().split("\n")
    let bus = -1
    for (const line of lines) {
      const busMatch = line.match(/^bus=(\d+)$/)
      if (busMatch) { bus = parseInt(busMatch[1]); continue }
      if (bus < 0) continue
      const g = line.match(/current value\s*=\s*(\d+).*max value\s*=\s*(\d+)/)
      if (!g) continue
      const cur = parseInt(g[1])
      const mx = parseInt(g[2])
      if (line.includes("0x16")) {
        Root.Config.gainBase[bus] = Root.Config.gainBase[bus] || {}; Root.Config.gainBase[bus].r = cur
        Root.Config.gainMax[bus] = Root.Config.gainMax[bus] || {}; Root.Config.gainMax[bus].r = mx
      } else if (line.includes("0x18")) {
        Root.Config.gainBase[bus] = Root.Config.gainBase[bus] || {}; Root.Config.gainBase[bus].g = cur
        Root.Config.gainMax[bus] = Root.Config.gainMax[bus] || {}; Root.Config.gainMax[bus].g = mx
      } else if (line.includes("0x1A")) {
        Root.Config.gainBase[bus] = Root.Config.gainBase[bus] || {}; Root.Config.gainBase[bus].b = cur
        Root.Config.gainMax[bus] = Root.Config.gainMax[bus] || {}; Root.Config.gainMax[bus].b = mx
      }
    }
  }

  function gainForBus(bus: int, channel: string): int {
    const b = Root.Config.gainBase[bus]
    const m = Root.Config.gainMax[bus]
    if (!b || !m) return 50
    const base = b[channel] ?? 50
    const max = m[channel] ?? 100
    if (channel === "r") return Math.round(base + (Root.Config.warmth / 100) * (max - base))
    if (channel === "b") return Math.round(base - (Root.Config.warmth / 100) * base)
    return base
  }

  function applyWarmthSet() {
    const cmds = []
    for (const bus of Root.Config.ddcBuses) {
      if (Root.Config.warmthEnabled) {
        cmds.push("timeout 5 ddcutil --sleep-multiplier 0.3 --bus " + bus + " setvcp 16 " + gainForBus(bus, "r") + " &")
        cmds.push("timeout 5 ddcutil --sleep-multiplier 0.3 --bus " + bus + " setvcp 18 " + gainForBus(bus, "g") + " &")
        cmds.push("timeout 5 ddcutil --sleep-multiplier 0.3 --bus " + bus + " setvcp 1A " + gainForBus(bus, "b") + " &")
      } else {
        const b = Root.Config.gainBase[bus]
        if (b) {
          cmds.push("timeout 5 ddcutil --sleep-multiplier 0.3 --bus " + bus + " setvcp 16 " + b.r + " &")
          cmds.push("timeout 5 ddcutil --sleep-multiplier 0.3 --bus " + bus + " setvcp 18 " + b.g + " &")
          cmds.push("timeout 5 ddcutil --sleep-multiplier 0.3 --bus " + bus + " setvcp 1A " + b.b + " &")
        } else {
          cmds.push("timeout 5 ddcutil --sleep-multiplier 0.3 --bus " + bus + " setvcp 16 50 &")
          cmds.push("timeout 5 ddcutil --sleep-multiplier 0.3 --bus " + bus + " setvcp 18 50 &")
          cmds.push("timeout 5 ddcutil --sleep-multiplier 0.3 --bus " + bus + " setvcp 1A 50 &")
        }
      }
    }
    if (cmds.length > 0) {
      cmds.push("wait")
      warmthProcess.command = ["sh", "-c", cmds.join("; ")]
      warmthProcess.running = true
    }
  }

  function applyWarmth() {
    if (Root.Config.brightnessBackend !== "ddc" || Root.Config.ddcBuses.length === 0) return
    if (Root.Config.warmthEnabled && !Root.Config.gainsLoaded) {
      readingGains = true
      const parts = []
      for (let gi = 0; gi < Root.Config.ddcBuses.length; gi++) {
        const gb = Root.Config.ddcBuses[gi]
        parts.push("{ echo bus=" + gb + "; timeout 5 ddcutil --sleep-multiplier 0.3 --bus " + gb + " getvcp 16; timeout 5 ddcutil --sleep-multiplier 0.3 --bus " + gb + " getvcp 18; timeout 5 ddcutil --sleep-multiplier 0.3 --bus " + gb + " getvcp 1A; } &")
      }
      parts.push("wait")
      warmthProcess.command = ["sh", "-c", parts.join("; ")]
      warmthProcess.running = true
      return
    }
    applyWarmthSet()
  }

  function toggleWarmth() {
    Root.Config.warmthEnabled = !Root.Config.warmthEnabled
    warmthDebounce.stop()
    applyWarmth()
    showTemporarily()
  }

  function setWarmth(value: int) {
    Root.Config.warmth = Math.max(0, Math.min(100, Math.round(value)))
    if (Root.Config.warmthEnabled) warmthDebounce.restart()
    showTemporarily()
  }

  Timer {
    id: warmthDebounce
    interval: 200
    onTriggered: applyWarmth()
  }

  onMenuOpenChanged: {
    bar.popupActive = menuOpen
    if (!menuOpen) bar.popupMouseInside = false
    if (menuOpen) {
      hideTimer.stop()
      popupVisible = true
      pollProcess.running = true
    } else {
      autoHideTimer.stop()
      hideTimer.start()
    }
  }

  Connections {
    target: bar
    function onPopupActiveChanged() {
      if (!bar.popupActive && menuOpen) menuOpen = false
    }
    function onCloseAllMenus() {
      menuOpen = false
    }
  }

  Timer {
    id: hideTimer
    interval: Root.Config.popupAnimDuration + 50
    onTriggered: {
      popupVisible = false
      bar.popupMouseInside = false
    }
  }

  Timer {
    id: autoHideTimer
    interval: autoHideDelay
    onTriggered: {
      if (!popup.mouseInside) menuOpen = false
    }
  }

  implicitWidth: displayButton.width
  implicitHeight: displayButton.height

  Rectangle {
    id: displayButton
    width: 24
    height: 24
    radius: 6
    color: buttonArea.containsMouse ? Qt.lighter(Root.Theme.primary, 1.15)
      : (menuOpen ? Qt.lighter(Root.Theme.primary, 1.1) : Root.Theme.primary)

    Behavior on color { ColorAnimation { duration: 100 } }

    Image {
      anchors.centerIn: parent
      source: "../assets/brightness.svg"
      sourceSize.width: 14
      sourceSize.height: 14
    }

    MouseArea {
      id: buttonArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton
      onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton) {
          setBrightness(Root.Config.brightnessPercent >= 50 ? 0 : 100)
          if (menuOpen) autoHideTimer.restart()
        } else {
          if (!menuOpen) bar.closeAllMenus()
          menuOpen = !menuOpen
          if (menuOpen) autoHideTimer.restart()
        }
      }
      onWheel: wheel => {
        adjustBrightness(wheel.angleDelta.y > 0 ? Root.Config.displayStep : -Root.Config.displayStep)
      }
    }
  }

  PopupWindow {
    id: popup
    anchor {
      window: panelWindow
      rect.x: panelWindow.width - popupContent.width - 8
      rect.y: panelWindow.height + panelWindow.popupOffset
      edges: Edges.Top | Edges.Left
    }

    visible: popupVisible
    implicitWidth: popupContent.width
    implicitHeight: popupContent.height
    color: "transparent"

    property bool mouseInside: false

    onVisibleChanged: {
      if (!visible) mouseInside = false
    }

    Components.PopupPanel {
      id: popupContent
      width: 232
      height: 132
      open: menuOpen

      HoverHandler {
        onHoveredChanged: {
          if (hovered) {
            popup.mouseInside = true
            bar.popupMouseInside = true
            autoHideTimer.stop()
          } else {
            popup.mouseInside = false
            bar.popupMouseInside = false
            autoHideTimer.restart()
          }
        }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Brightness row
        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          Components.Button {
            source: "../assets/minus.svg"
            onClicked: { adjustBrightness(-Root.Config.displayStep); autoHideTimer.restart() }
          }

          Slider {
            id: brightnessSlider
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter

            from: 0
            to: 100
            value: Root.Config.brightnessPercent
            stepSize: 1

            Behavior on value { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            onMoved: {
              scheduleBrightness(value)
              autoHideTimer.restart()
            }

            background: Rectangle {
              x: brightnessSlider.leftPadding
              y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
              width: brightnessSlider.availableWidth
              height: 6
              radius: 3
              color: Root.Theme.overlay

              Rectangle {
                width: Math.min(brightnessSlider.visualPosition * parent.width, parent.width)
                height: parent.height
                radius: 3
                color: Root.Theme.primary
              }
            }

            handle: Rectangle {
              x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
              y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
              width: 14
              height: 14
              radius: 7
              color: brightnessSlider.pressed ? Root.Theme.surfaceHover : Root.Theme.text
              border.color: Root.Theme.primary
              border.width: 2
              Behavior on color { ColorAnimation { duration: 100 } }
            }
          }

          Components.Button {
            source: "../assets/plus.svg"
            onClicked: { adjustBrightness(Root.Config.displayStep); autoHideTimer.restart() }
          }

          Rectangle {
            width: 46
            height: 28
            radius: 6
            color: Root.Theme.surface

            Text {
              anchors.centerIn: parent
              text: Root.Config.brightnessPercent + "%"
              color: Root.Theme.text
              font.pixelSize: 14
              font.bold: true
              font.family: Root.Theme.fontFamily
            }
          }
        }

        // Brightness presets
        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          Components.Button {
            text: "dim"
            Layout.preferredHeight: 26
            Layout.fillWidth: true
            onClicked: { presetBrightness(Root.Config.displayDim); autoHideTimer.restart() }
          }
          Components.Button {
            text: "low"
            Layout.preferredHeight: 26
            Layout.fillWidth: true
            onClicked: { presetBrightness(Root.Config.displayLow); autoHideTimer.restart() }
          }
          Components.Button {
            text: "mid"
            Layout.preferredHeight: 26
            Layout.fillWidth: true
            onClicked: { presetBrightness(Root.Config.displayMid); autoHideTimer.restart() }
          }
          Components.Button {
            text: "max"
            Layout.preferredHeight: 26
            Layout.fillWidth: true
            onClicked: { presetBrightness(100); autoHideTimer.restart() }
          }
        }

        // Warmth row
        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          Rectangle {
            width: 40
            height: 20
            radius: 10
            color: Root.Config.warmthEnabled ? Root.Theme.accent : Root.Theme.overlay

            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
              width: 16
              height: 16
              radius: 8
              color: Root.Theme.text
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: Root.Config.warmthEnabled ? 22 : 2

              Behavior on anchors.leftMargin {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: { toggleWarmth(); autoHideTimer.restart() }
            }
          }

          Image {
            source: "../assets/warmth.svg"
            sourceSize.width: 16
            sourceSize.height: 16
          }

          Slider {
            id: warmthSlider
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter

            from: 0
            to: 100
            value: Root.Config.warmth
            stepSize: 1
            enabled: Root.Config.warmthEnabled

            Behavior on value { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            onMoved: {
              setWarmth(value)
              autoHideTimer.restart()
            }

            background: Rectangle {
              x: warmthSlider.leftPadding
              y: warmthSlider.topPadding + warmthSlider.availableHeight / 2 - height / 2
              width: warmthSlider.availableWidth
              height: 6
              radius: 3
              color: Root.Theme.overlay

              Rectangle {
                width: Math.min(warmthSlider.visualPosition * parent.width, parent.width)
                height: parent.height
                radius: 3
                color: Root.Config.warmthEnabled ? Root.Theme.warning : Root.Theme.overlay
              }
            }

            handle: Rectangle {
              x: warmthSlider.leftPadding + warmthSlider.visualPosition * (warmthSlider.availableWidth - width)
              y: warmthSlider.topPadding + warmthSlider.availableHeight / 2 - height / 2
              width: 14
              height: 14
              radius: 7
              color: warmthSlider.pressed ? Root.Theme.surfaceHover : Root.Theme.text
              border.color: Root.Config.warmthEnabled ? Root.Theme.warning : Root.Theme.overlay
              border.width: 2
              Behavior on color { ColorAnimation { duration: 100 } }
            }
          }

          Rectangle {
            width: 46
            height: 28
            radius: 6
            color: Root.Theme.surface

            Text {
              anchors.centerIn: parent
              text: Root.Config.warmthEnabled ? (Root.Config.warmth + "%") : "off"
              color: Root.Config.warmthEnabled ? Root.Theme.text : Root.Theme.textMuted
              font.pixelSize: 13
              font.bold: true
              font.family: Root.Theme.fontFamily
            }
          }
        }
      }
    }
  }
}
