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
  property bool selfTriggered: false
  property int pendingDebouncedBrightness: -1

  Process {
    id: pollProcess
    command: ["sh", "-c", "echo $(brightnessctl" + deviceFlag + " get) $(brightnessctl" + deviceFlag + " max)"]
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = text.trim().split(/\s+/)
        if (parts.length === 2) {
          const current = parseInt(parts[0])
          const max = parseInt(parts[1])
          if (!isNaN(current) && !isNaN(max) && max > 0) {
            const newPercent = Math.round((current / max) * 100)
            if (!initialized) {
              initialized = true
              Root.Config.brightnessPercent = newPercent
              Root.Config.previousBrightnessPercent = newPercent
              return
            }
            if (!selfTriggered && newPercent !== Root.Config.brightnessPercent) {
              Root.Config.brightnessPercent = newPercent
              if (newPercent !== Root.Config.previousBrightnessPercent) {
                Root.Config.previousBrightnessPercent = newPercent
                showTemporarily()
              }
            }
          }
        }
      }
    }
    onExited: {
      if (!running) restartTimer.start()
    }
  }

  Timer {
    id: restartTimer
    interval: 100
    onTriggered: pollProcess.running = true
  }

  Component.onCompleted: {
    backlightDetect.running = true
  }

  Process {
    id: backlightDetect
    command: ["sh", "-c", 'best=""; bestmax=0; for d in /sys/class/backlight/*/; do [ -e "$d/max_brightness" ] || continue; m=$(cat "$d/max_brightness" 2>/dev/null); case "$m" in (*[!0-9]*)) continue;; esac; if [ "$m" -gt "$bestmax" ]; then bestmax=$m; best=$(basename "$d"); fi; done; echo "$best"']
    stdout: StdioCollector {
      onStreamFinished: {
        const dev = text.trim()
        if (dev.length > 0) Root.Config.backlightDevice = dev
        pollProcess.running = true
      }
    }
  }

  function showTemporarily() {
    if (bar.screen.name != Root.Config.focusedScreenName) return
    if (!menuOpen) bar.closeAllMenus()
    menuOpen = true
    autoHideTimer.restart()
  }

  Process {
    id: setProcess
    onExited: {
      selfTriggered = false
      resyncTimer.start()
    }
  }

  function setBrightness(percent: int) {
    percent = Math.max(0, Math.min(100, Math.round(percent)))
    Root.Config.brightnessPercent = percent
    Root.Config.previousBrightnessPercent = percent
    selfTriggered = true
    const args = ["brightnessctl"]
    if (Root.Config.backlightDevice) args.push("-d", Root.Config.backlightDevice)
    args.push("set", percent + "%")
    setProcess.command = args
    setProcess.running = true
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

  function adjustBrightness(normDelta: real) {
    setBrightness(Root.Config.brightnessPercent + normDelta * 100)
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

  implicitWidth: button.width
  implicitHeight: button.height

  Rectangle {
    id: button
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
        adjustBrightness(wheel.angleDelta.y > 0 ? Root.Config.brightnessStep : -Root.Config.brightnessStep)
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
      width: 220
      height: 60
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

      RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        Components.Button {
          source: "../assets/minus.svg"
          onClicked: { adjustBrightness(-Root.Config.brightnessStep); autoHideTimer.restart() }
        }

        Slider {
          id: slider
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
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 6
            radius: 3
            color: Root.Theme.overlay

            Rectangle {
              width: Math.min(slider.visualPosition * parent.width, parent.width)
              height: parent.height
              radius: 3
              color: Root.Theme.primary
            }
          }

          handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 14
            height: 14
            radius: 7
            color: slider.pressed ? Root.Theme.surfaceHover : Root.Theme.text
            border.color: Root.Theme.primary
            border.width: 2
            Behavior on color { ColorAnimation { duration: 100 } }
          }
        }

        Components.Button {
          source: "../assets/plus.svg"
          onClicked: { adjustBrightness(Root.Config.brightnessStep); autoHideTimer.restart() }
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
    }
  }
}
