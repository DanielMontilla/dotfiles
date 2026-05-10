import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".." as Root

Item {
  id: root
  property var panelWindow

  property bool menuOpen: false
  property bool popupVisible: false

  readonly property int animDuration: 250
  readonly property int autoHideDelay: 1000

  // Track if we triggered the change ourselves
  property bool selfTriggered: false
  // Skip first notification on startup
  property bool initialized: false
   
  // Keyboard backlight percentage 0-100
  property int kbBrightnessPercent: 0
  property int previousKbPercent: 0
  property bool hasKeyboardBacklight: false

  // Night mode state - tracked internally since gammastep -O exits immediately
  property bool nightModeEnabled: false

  // Keyboard device name
  property string keyboardDevice: "chromeos::kbd_backlight"

  // Process for polling keyboard brightness
  Process {
    id: kbPollProcess
    command: ["sh", "-c", `echo $(brightnessctl --device='${keyboardDevice}' get 2>/dev/null || echo 0) $(brightnessctl --device='${keyboardDevice}' max 2>/dev/null || echo 0)`]
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = text.trim().split(/\s+/)
        if (parts.length === 2) {
          const current = parseInt(parts[0])
          const max = parseInt(parts[1])
          if (!isNaN(current) && !isNaN(max) && max > 0) {
            hasKeyboardBacklight = true
            const newPercent = Math.round((current / max) * 100)
            if (!initialized) {
              kbBrightnessPercent = newPercent
              previousKbPercent = newPercent
              return
            }
            if (!selfTriggered && hasKeyboardBacklight) {
              kbBrightnessPercent = newPercent
              if (newPercent !== previousKbPercent) {
                previousKbPercent = newPercent
                showTemporarily()
              }
            }
          } else {
            hasKeyboardBacklight = false
          }
        }
      }
    }
    onExited: {
      if (!running) {
        kbRestartTimer.start()
      }
    }
  }

  Timer {
    id: kbRestartTimer
    interval: 500
    onTriggered: {
      kbPollProcess.running = true
    }
  }

  // Start polling on load
  Component.onCompleted: {
    kbPollProcess.running = true
  }

  function showTemporarily() {
    menuOpen = true
    autoHideTimer.restart()
  }

  function setKbBrightness(percent: int) {
    if (!hasKeyboardBacklight) return
    selfTriggered = true
    Quickshell.execDetached(["brightnessctl", "--device", keyboardDevice, "set", percent + "%"])
    kbBrightnessPercent = percent
    previousKbPercent = percent
    kbResetTimer.restart()
  }

  Timer {
    id: kbResetTimer
    interval: 300
    onTriggered: selfTriggered = false
  }

  function toggleNightMode() {
    if (nightModeEnabled) {
      // Turn off - reset gamma ramps
      Quickshell.execDetached(["gammastep", "-x"])
      nightModeEnabled = false
    } else {
      // Turn on - warm temperature, reduced brightness
      Quickshell.execDetached(["gammastep", "-O", "4000", "-b", "0.8"])
      nightModeEnabled = true
    }
  }

  onMenuOpenChanged: {
    if (menuOpen) {
      hideTimer.stop()
      popupVisible = true
      // Refresh keyboard state
      kbPollProcess.running = true
    } else {
      autoHideTimer.stop()
      hideTimer.start()
    }
  }

  Timer {
    id: hideTimer
    interval: animDuration + 50
    onTriggered: popupVisible = false
  }

  Timer {
    id: autoHideTimer
    interval: autoHideDelay
    onTriggered: {
      if (!popup.mouseInside) {
        menuOpen = false
      }
    }
  }

  implicitWidth: nightButton.width
  implicitHeight: nightButton.height

  // Night button (moon icon)
  Rectangle {
    id: nightButton
    width: 24
    height: 24
    radius: 6
    color: buttonArea.containsMouse ? Root.Theme.surfaceHover : (menuOpen ? Root.Theme.surface : "transparent")

    Behavior on color {
      ColorAnimation { duration: 100 }
    }

    Image {
      anchors.centerIn: parent
      source: "../assets/moon.svg"
      sourceSize.width: 14
      sourceSize.height: 14
    }

    MouseArea {
      id: buttonArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: menuOpen = !menuOpen
    }
  }

  // Night mode popup
  PopupWindow {
    id: popup
    anchor {
      window: panelWindow
      rect.x: panelWindow.width - popupContent.width - 8
      rect.y: nightButton.height + 12
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

    Rectangle {
      id: popupContent
      width: 200
      // Height depends on whether keyboard is available
      height: hasKeyboardBacklight ? 110 : 56
      radius: 8
      color: Root.Theme.background
      border.color: Root.Theme.surface
      border.width: 1

      scale: menuOpen ? 1 : 0.95
      opacity: menuOpen ? 1 : 0
      transformOrigin: Item.TopRight

      Behavior on scale {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
      }
      Behavior on opacity {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
      }

      HoverHandler {
        id: contentHover
        onHoveredChanged: {
          if (hovered) {
            popup.mouseInside = true
            autoHideTimer.stop()
          } else if (popup.mouseInside) {
            popup.mouseInside = false
            autoHideTimer.restart()
          }
        }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // Keyboard backlight row (only if available)
        RowLayout {
          Layout.fillWidth: true
          spacing: 10
          visible: hasKeyboardBacklight

          // Keyboard icon
          Rectangle {
            width: 24
            height: 24
            radius: 4
            color: "transparent"

            Image {
              anchors.centerIn: parent
              source: "../assets/keyboard.svg"
              sourceSize.width: 16
              sourceSize.height: 16
            }
          }

          // Keyboard brightness slider
          Slider {
            id: kbSlider
            Layout.fillWidth: true
            Layout.preferredHeight: 24

            from: 0
            to: 100
            value: kbBrightnessPercent
            stepSize: 1

            onMoved: {
              setKbBrightness(value)
              autoHideTimer.restart()
            }

            background: Rectangle {
              x: kbSlider.leftPadding
              y: kbSlider.topPadding + kbSlider.availableHeight / 2 - height / 2
              width: kbSlider.availableWidth
              height: 6
              radius: 3
              color: Root.Theme.surface

              Rectangle {
                width: kbSlider.visualPosition * parent.width
                height: parent.height
                radius: 3
                color: Root.Theme.primary
              }
            }

            handle: Rectangle {
              x: kbSlider.leftPadding + kbSlider.visualPosition * (kbSlider.availableWidth - width)
              y: kbSlider.topPadding + kbSlider.availableHeight / 2 - height / 2
              width: 14
              height: 14
              radius: 7
              color: kbSlider.pressed ? Root.Theme.surfaceHover : Root.Theme.text
              border.color: Root.Theme.primary
              border.width: 2

              Behavior on color {
                ColorAnimation { duration: 100 }
              }
            }
          }

          // Percentage display
          Text {
            text: kbBrightnessPercent + "%"
            color: Root.Theme.text
            font.pixelSize: 11
            font.family: Root.Theme.fontFamily
            Layout.preferredWidth: 32
            horizontalAlignment: Text.AlignRight
          }
        }

        // Night mode toggle row
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          // Moon icon
          Rectangle {
            width: 24
            height: 24
            radius: 4
            color: "transparent"

            Image {
              anchors.centerIn: parent
              source: "../assets/moon.svg"
              sourceSize.width: 16
              sourceSize.height: 16
            }
          }

          // Night mode label
          Text {
            text: "Night Mode"
            color: Root.Theme.text
            font.pixelSize: 13
            font.family: Root.Theme.fontFamily
            Layout.fillWidth: true
          }

          // Toggle switch
          Rectangle {
            width: 40
            height: 20
            radius: 10
            color: nightModeEnabled ? Root.Theme.primary : Root.Theme.surface

            Behavior on color {
              ColorAnimation { duration: 150 }
            }

            Rectangle {
              width: 16
              height: 16
              radius: 8
              color: Root.Theme.text
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: nightModeEnabled ? 22 : 2

              Behavior on anchors.leftMargin {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                toggleNightMode()
                autoHideTimer.restart()
              }
            }
          }
        }
      }
    }
  }
}
