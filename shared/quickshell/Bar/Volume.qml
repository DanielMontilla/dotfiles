import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
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

  // Audio state
  readonly property PwNode sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
  readonly property real volume: sink?.audio?.volume ?? 0
  readonly property bool muted: sink?.audio?.muted ?? false

  // Track if we triggered the volume change ourselves
  property bool selfTriggered: false
  // Skip first volume notification on startup
  property bool initialized: false

  // Bind sink to track its properties
  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }

  // Watch for external volume changes
  Connections {
    target: sink?.audio ?? null
    function onVolumeChanged() {
      if (!initialized) {
        initialized = true
        return
      }
      if (!selfTriggered) {
        showTemporarily()
      }
      selfTriggered = false
    }
    function onMutedChanged() {
      if (!initialized) return
      if (!selfTriggered) {
        showTemporarily()
      }
      selfTriggered = false
    }
  }

  function showTemporarily() {
    menuOpen = true
    autoHideTimer.restart()
  }

  function setVolume(newVol: real) {
    if (!sink?.audio) return
    selfTriggered = true
    sink.audio.volume = Math.max(0, Math.min(1, newVol))
  }

  function toggleMute() {
    if (!sink?.audio) return
    selfTriggered = true
    sink.audio.muted = !sink.audio.muted
  }

  function getIconSource(): string {
    if (muted) return "../assets/volume-mute.svg"
    if (volume < 0.01) return "../assets/volume-none.svg"
    if (volume < 0.5) return "../assets/volume-low.svg"
    return "../assets/volume-loud.svg"
  }

  onMenuOpenChanged: {
    if (menuOpen) {
      hideTimer.stop()
      popupVisible = true
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

  implicitWidth: volumeButton.width
  implicitHeight: volumeButton.height

  // Volume button
  Rectangle {
    id: volumeButton
    width: 24
    height: 24
    radius: 6
    color: buttonArea.containsMouse ? Root.Theme.surfaceHover : (menuOpen ? Root.Theme.surface : "transparent")

    Behavior on color {
      ColorAnimation { duration: 100 }
    }

    Image {
      anchors.centerIn: parent
      source: getIconSource()
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
          toggleMute()
        } else {
          menuOpen = !menuOpen
          if (menuOpen) autoHideTimer.restart()
        }
      }
      onWheel: wheel => {
        const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
        setVolume(volume + delta)
        showTemporarily()
      }
    }
  }

  // Volume popup
  PopupWindow {
    id: popup
    anchor {
      window: panelWindow
      rect.x: panelWindow.width - sliderContent.width - 8
      rect.y: volumeButton.height + 12
      edges: Edges.Top | Edges.Left
    }

    visible: popupVisible

    implicitWidth: sliderContent.width
    implicitHeight: sliderContent.height

    color: "transparent"

    property bool mouseInside: false

    onVisibleChanged: {
      if (!visible) mouseInside = false
    }

    Rectangle {
      id: sliderContent
      width: 200
      height: 56
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
            autoHideTimer.restart()
          }
        }
      }

      RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Mute button
        Rectangle {
          width: 24
          height: 24
          radius: 4
          color: muteArea.containsMouse ? Root.Theme.surfaceHover : "transparent"

          Image {
            anchors.centerIn: parent
            source: getIconSource()
            sourceSize.width: 16
            sourceSize.height: 16
          }

          MouseArea {
            id: muteArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: toggleMute()
          }
        }

        // Volume slider
        Slider {
          id: slider
          Layout.fillWidth: true
          Layout.preferredHeight: 24

          from: 0
          to: 1
          value: volume
          stepSize: 0.01

          onMoved: {
            setVolume(value)
            autoHideTimer.restart()
          }

          background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 6
            radius: 3
            color: Root.Theme.surface

            Rectangle {
              width: slider.visualPosition * parent.width
              height: parent.height
              radius: 3
              color: muted ? Root.Theme.overlay : Root.Theme.primary
            }
          }

          handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 14
            height: 14
            radius: 7
            color: slider.pressed ? Root.Theme.surfaceHover : Root.Theme.text
            border.color: muted ? Root.Theme.overlay : Root.Theme.primary
            border.width: 2

            Behavior on color {
              ColorAnimation { duration: 100 }
            }
          }
        }

        // Volume percentage
        Text {
          text: Math.round(volume * 100) + "%"
          color: Root.Theme.text
          font.pixelSize: 11
          font.family: Root.Theme.fontFamily
          Layout.preferredWidth: 32
          horizontalAlignment: Text.AlignRight
        }
      }
    }
  }
}

