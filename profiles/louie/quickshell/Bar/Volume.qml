import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".." as Root
import "../Components" as Components

Item {
  id: root
  property var panelWindow

  property bool menuOpen: false
  property bool popupVisible: false

  readonly property int animDuration: 250
  readonly property int autoHideDelay: 2000

  readonly property real lowThreshold: 0.3

  readonly property PwNode sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
  readonly property real volume: sink?.audio?.volume ?? 0
  readonly property bool muted: sink?.audio?.muted ?? false

  property bool selfTriggered: false
  property bool initialized: false

  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }

  Connections {
    target: sink?.audio ?? null
    function onVolumeChanged() {
      if (!initialized) { initialized = true; return }
      if (!selfTriggered) showTemporarily()
      selfTriggered = false
    }
    function onMutedChanged() {
      if (!initialized) return
      if (!selfTriggered) showTemporarily()
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
    sink.audio.volume = Math.max(0, Math.min(Root.Config.maxVolume, newVol))
  }

  function toggleMute() {
    if (!sink?.audio) return
    selfTriggered = true
    sink.audio.muted = !sink.audio.muted
  }

  function adjustVolume(normDelta: real) {
    setVolume(volume + normDelta * Root.Config.maxVolume)
    showTemporarily()
  }

  function presetVolume(pct: real) {
    setVolume((pct / 100) * Root.Config.maxVolume)
    showTemporarily()
  }

  function getIconSource(): string {
    if (muted) return "../assets/volume-mute.svg"
    if (volume < 0.01) return "../assets/volume-none.svg"
    if (volume < lowThreshold) return "../assets/volume-low.svg"
    return "../assets/volume-loud.svg"
  }

  onMenuOpenChanged: {
    Root.Config.popupActive = menuOpen
    if (!menuOpen) Root.Config.popupMouseInside = false
    if (menuOpen) {
      hideTimer.stop()
      popupVisible = true
    } else {
      autoHideTimer.stop()
      hideTimer.start()
    }
  }

  Connections {
    target: Root.Config
    function onPopupActiveChanged() {
      if (!Root.Config.popupActive && menuOpen) {
        menuOpen = false
      }
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
      if (!popup.mouseInside) menuOpen = false
    }
  }

  implicitWidth: volumeButton.width
  implicitHeight: volumeButton.height

  Rectangle {
    id: volumeButton
    width: 24
    height: 24
    radius: 6
    color: buttonArea.containsMouse ? Root.Theme.surfaceHover : (menuOpen ? Root.Theme.surface : "transparent")

    Behavior on color { ColorAnimation { duration: 100 } }

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
          if (menuOpen) autoHideTimer.restart()
        } else {
          menuOpen = !menuOpen
          if (menuOpen) autoHideTimer.restart()
        }
      }
      onWheel: wheel => {
        adjustVolume(wheel.angleDelta.y > 0 ? Root.Config.changeInterval : -Root.Config.changeInterval)
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
      width: 220
      height: 88

      scale: menuOpen ? 1 : 0.95
      opacity: menuOpen ? 1 : 0
      transformOrigin: Item.TopRight

      Behavior on scale {
        NumberAnimation { duration: animDuration; easing.type: Easing.OutCubic }
      }
      Behavior on opacity {
        NumberAnimation { duration: animDuration; easing.type: Easing.OutCubic }
      }

      HoverHandler {
        onHoveredChanged: {
          if (hovered) {
            popup.mouseInside = true
            Root.Config.popupMouseInside = true
            autoHideTimer.stop()
          } else {
            popup.mouseInside = false
            Root.Config.popupMouseInside = false
            autoHideTimer.restart()
          }
        }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          Components.Button {
            source: "../assets/minus.svg"
            onClicked: { adjustVolume(-Root.Config.changeInterval); autoHideTimer.restart() }
          }

          Slider {
            id: slider
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter

            from: 0
            to: Root.Config.maxVolume
            value: volume
            stepSize: 0.01

            Behavior on value {
              NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

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
              color: Root.Theme.overlay

              Rectangle {
                width: Math.min(slider.visualPosition * parent.width, parent.width)
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
              Behavior on color { ColorAnimation { duration: 100 } }
            }
          }

          Components.Button {
            source: "../assets/plus.svg"
            onClicked: { adjustVolume(Root.Config.changeInterval); autoHideTimer.restart() }
          }

          Rectangle {
            width: 48
            height: 28
            radius: 6
            color: Root.Theme.surface

            Text {
              anchors.centerIn: parent
              text: Math.round(volume / Root.Config.maxVolume * 100) + "%"
              color: Root.Theme.text
              font.pixelSize: 14
              font.bold: true
              font.strikeout: muted
              font.family: Root.Theme.fontFamily
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          Components.Button {
            source: "../assets/volume-mute.svg"
            Layout.preferredHeight: 28
            Layout.fillWidth: true
            onClicked: { toggleMute(); autoHideTimer.restart() }
          }
          Components.Button {
            text: "low"
            Layout.preferredHeight: 28
            Layout.fillWidth: true
            onClicked: { setVolume(Root.Config.lowVolume * Root.Config.maxVolume); autoHideTimer.restart() }
          }
          Components.Button {
            text: "mid"
            Layout.preferredHeight: 28
            Layout.fillWidth: true
            onClicked: { setVolume(Root.Config.midVolume * Root.Config.maxVolume); autoHideTimer.restart() }
          }
          Components.Button {
            text: "max"
            Layout.preferredHeight: 28
            Layout.fillWidth: true
            onClicked: { setVolume(Root.Config.maxVolume); autoHideTimer.restart() }
          }
        }
      }
    }
  }
}
