import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".." as Root
import "../Components" as Components

Item {
  id: root
  property var panelWindow
  property var bar

  property bool menuOpen: false
  property bool popupVisible: false

  readonly property int autoHideDelay: 2000

  function run(command: var) {
    Quickshell.execDetached(command)
    menuOpen = false
  }

  onMenuOpenChanged: {
    bar.popupActive = menuOpen
    if (!menuOpen) bar.popupMouseInside = false
    if (menuOpen) {
      hideTimer.stop()
      popupVisible = true
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

  implicitWidth: powerButton.width
  implicitHeight: powerButton.height

  Rectangle {
    id: powerButton
    width: 24
    height: 24
    radius: 6
    color: buttonArea.containsMouse ? Qt.lighter(Root.Theme.primary, 1.15)
      : (menuOpen ? Qt.lighter(Root.Theme.primary, 1.1) : Root.Theme.primary)

    Behavior on color { ColorAnimation { duration: 100 } }

    Image {
      anchors.centerIn: parent
      source: "../assets/power.svg"
      sourceSize.width: 14
      sourceSize.height: 14
    }

    MouseArea {
      id: buttonArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        if (!menuOpen) bar.closeAllMenus()
        menuOpen = !menuOpen
        if (menuOpen) autoHideTimer.restart()
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
      width: 180
      height: actionColumn.implicitHeight + 20
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
        id: actionColumn
        anchors {
          top: parent.top
          left: parent.left
          right: parent.right
          margins: 10
        }
        spacing: 4

        Repeater {
          model: [
            { icon: "../assets/lock.svg",       label: "Lock",     cmd: ["sh", "-c", "loginctl lock-session"] },
            { icon: "../assets/logout.svg",      label: "Logout",   cmd: ["sh", "-c", "loginctl terminate-session $XDG_SESSION_ID"] },
            { icon: "../assets/suspend.svg",     label: "Suspend",  cmd: ["sh", "-c", "systemctl suspend"] },
            { icon: "../assets/restart.svg",     label: "Reboot",   cmd: ["sh", "-c", "systemctl reboot"] },
            { icon: "../assets/power.svg",       label: "Shutdown", cmd: ["sh", "-c", "systemctl poweroff"] },
          ]

          delegate: Rectangle {
            id: row
            required property var modelData

            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 6
            color: rowArea.containsMouse ? Qt.lighter(Root.Theme.surface, 1.6) : "transparent"

            Behavior on color { ColorAnimation { duration: 100 } }

            Image {
              anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
              }
              source: modelData.icon
              sourceSize.width: 16
              sourceSize.height: 16
            }

            Text {
              anchors {
                left: parent.left
                leftMargin: 36
                verticalCenter: parent.verticalCenter
              }
              text: modelData.label
              color: rowArea.containsMouse ? Root.Theme.text : Root.Theme.textMuted
              font.pixelSize: 13
              font.family: Root.Theme.fontFamily
            }

            Rectangle {
              anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 8
                rightMargin: 8
              }
              height: 1
              color: Root.Theme.overlay
              visible: rowArea.containsMouse
            }

            MouseArea {
              id: rowArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.run(modelData.cmd)
            }
          }
        }
      }
    }
  }
}
