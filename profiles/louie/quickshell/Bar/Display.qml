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

  readonly property int animDuration: 250
  readonly property int autoHideDelay: 2000

  // Brightness state (0-100)
  property int brightnessPercent: 100
  property int previousBrightnessPercent: 100
  property bool selfTriggered: false
  property bool initialized: false

  // Warmth state
  property bool warmthEnabled: false
  // Warmth amount 0 (neutral) - 100 (warmest)
  property int warmth: 50

  // Map warmth 0-100 to a gammastep temperature (6500K neutral -> 2500K warm)
  readonly property int warmthTemp: Math.round(6500 - (warmth / 100) * 4000)

  // Brightness backend: "ddc" (external/desktop monitor via DDC/CI) or
  // "backlight" (laptop panel via /sys/class/backlight)
  property string brightnessBackend: ""
  property var ddcBuses: []
  property int brightnessMax: 100
  property string backlightDevice: ""
  readonly property string deviceFlag: backlightDevice ? (" -d " + backlightDevice) : ""

  // Prefer DDC/CI (desktop monitors); fall back to a panel backlight if none found
  Process {
    id: ddcDetect
    command: ["sh", "-c", "ddcutil detect 2>/dev/null | grep -oE '/dev/i2c-[0-9]+' | sed 's|/dev/i2c-||' | tr '\\n' ' '; echo"]
    stdout: StdioCollector {
      onStreamFinished: {
        const buses = text.trim().split(/\s+/).filter(b => b.length > 0).map(b => parseInt(b))
        if (buses.length > 0) {
          ddcBuses = buses
          brightnessBackend = "ddc"
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
        if (dev.length > 0) backlightDevice = dev
        brightnessBackend = "backlight"
        pollProcess.running = true
      }
    }
  }

  // Brightness polling
  Process {
    id: pollProcess
    command: brightnessBackend === "ddc"
      ? ["ddcutil", "--bus", ddcBuses.length > 0 ? String(ddcBuses[0]) : "1", "getvcp", "10"]
      : ["sh", "-c", "echo $(brightnessctl" + deviceFlag + " get) $(brightnessctl" + deviceFlag + " max)"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (brightnessBackend === "ddc") {
          const cur = text.match(/current value\s*=\s*(\d+)/)
          const mx = text.match(/max value\s*=\s*(\d+)/)
          if (cur && mx) {
            const current = parseInt(cur[1])
            const max = parseInt(mx[1])
            if (max > 0) {
              brightnessMax = max
              applyBrightnessReading(Math.round((current / max) * 100))
            }
          }
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

  function applyBrightnessReading(newPercent: int) {
    if (!initialized) {
      initialized = true
      brightnessPercent = newPercent
      previousBrightnessPercent = newPercent
      return
    }
    if (!selfTriggered) {
      brightnessPercent = newPercent
      if (newPercent !== previousBrightnessPercent) {
        previousBrightnessPercent = newPercent
        showTemporarily()
      }
    }
  }

  Timer {
    id: restartTimer
    interval: brightnessBackend === "ddc" ? 1500 : 100
    onTriggered: pollProcess.running = true
  }

  Component.onCompleted: ddcDetect.running = true

  function showTemporarily() {
    if (bar.screen.name != Root.Config.focusedScreenName) return
    menuOpen = true
    autoHideTimer.restart()
  }

  function setBrightness(percent: int) {
    percent = Math.max(0, Math.min(100, Math.round(percent)))
    selfTriggered = true
    if (brightnessBackend === "ddc") {
      const value = Math.round((percent / 100) * brightnessMax)
      const busList = ddcBuses.join(" ")
      Quickshell.execDetached(["sh", "-c",
        "for b in " + busList + "; do ddcutil --bus $b setvcp 10 " + value + "; done"])
    } else {
      const args = ["brightnessctl"]
      if (backlightDevice) args.push("-d", backlightDevice)
      args.push("set", percent + "%")
      Quickshell.execDetached(args)
    }
    brightnessPercent = percent
    previousBrightnessPercent = percent
    resetTimer.restart()
  }

  Timer {
    id: resetTimer
    interval: 300
    onTriggered: selfTriggered = false
  }

  function adjustBrightness(normDelta: real) {
    setBrightness(brightnessPercent + normDelta * 100)
    showTemporarily()
  }

  function presetBrightness(pct: int) {
    setBrightness(pct)
    showTemporarily()
  }

  function applyWarmth() {
    if (warmthEnabled) {
      Quickshell.execDetached(["sh", "-c",
        "pkill -x gammastep 2>/dev/null; gammastep -O " + warmthTemp])
    } else {
      Quickshell.execDetached(["gammastep", "-x"])
    }
  }

  function toggleWarmth() {
    warmthEnabled = !warmthEnabled
    applyWarmth()
    showTemporarily()
  }

  function setWarmth(value: int) {
    warmth = Math.max(0, Math.min(100, Math.round(value)))
    if (warmthEnabled) applyWarmth()
    showTemporarily()
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
  }

  Timer {
    id: hideTimer
    interval: animDuration + 50
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
          setBrightness(brightnessPercent >= 50 ? 0 : 100)
          if (menuOpen) autoHideTimer.restart()
        } else {
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

    Components.Panel {
      id: popupContent
      width: 232
      height: 132

      scale: menuOpen ? 1 : 0.95
      opacity: menuOpen ? 1 : 0
      transformOrigin: Item.TopRight

      Behavior on scale { NumberAnimation { duration: animDuration; easing.type: Easing.OutCubic } }
      Behavior on opacity { NumberAnimation { duration: animDuration; easing.type: Easing.OutCubic } }

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
            value: brightnessPercent
            stepSize: 1

            Behavior on value { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            onMoved: {
              setBrightness(value)
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
              text: brightnessPercent + "%"
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

          // Warmth toggle
          Rectangle {
            width: 40
            height: 20
            radius: 10
            color: warmthEnabled ? Root.Theme.accent : Root.Theme.overlay

            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
              width: 16
              height: 16
              radius: 8
              color: Root.Theme.text
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: warmthEnabled ? 22 : 2

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
            value: warmth
            stepSize: 1
            enabled: warmthEnabled

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
                color: warmthEnabled ? Root.Theme.warning : Root.Theme.overlay
              }
            }

            handle: Rectangle {
              x: warmthSlider.leftPadding + warmthSlider.visualPosition * (warmthSlider.availableWidth - width)
              y: warmthSlider.topPadding + warmthSlider.availableHeight / 2 - height / 2
              width: 14
              height: 14
              radius: 7
              color: warmthSlider.pressed ? Root.Theme.surfaceHover : Root.Theme.text
              border.color: warmthEnabled ? Root.Theme.warning : Root.Theme.overlay
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
              text: warmthEnabled ? (warmth + "%") : "off"
              color: warmthEnabled ? Root.Theme.text : Root.Theme.textMuted
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
