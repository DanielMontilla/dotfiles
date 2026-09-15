import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".." as Root
import "../Components" as Components

Item {
  id: root
  property var panelWindow
  property var bar

  property QtObject server: Root.NotificationCenter.server

  property bool menuOpen: false
  property bool popupVisible: false

  readonly property int autoHideDelay: 2000

  implicitWidth: btn.width
  implicitHeight: btn.height

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

  Rectangle {
    id: btn
    width: 24
    height: 24
    radius: 6
    color: buttonArea.containsMouse ? Qt.lighter(Root.Theme.primary, 1.15) : (menuOpen ? Qt.lighter(Root.Theme.primary, 1.1) : Root.Theme.primary)

    Behavior on color { ColorAnimation { duration: 100 } }

    Image {
      anchors.centerIn: parent
      source: "../assets/bell.svg"
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

    Components.Panel {
      id: popupContent
      width: Root.Config.notificationListWidth
      height: Root.Config.notificationListHeight

      opacity: menuOpen ? 1 : 0
      Behavior on opacity {
        NumberAnimation {
          duration: Root.Config.popupAnimDuration
          easing.type: Easing.OutCubic
        }
      }

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

        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          Text {
            Layout.fillWidth: true
            text: "Notifications"
            color: Root.Theme.text
            font.family: Root.Theme.fontFamily
            font.pixelSize: 14
            font.bold: true
          }

          Components.Button {
            text: "clear"
            Layout.preferredWidth: 48
            Layout.preferredHeight: 26
            onClicked: Root.NotificationCenter.clearAll()
          }
        }

        Rectangle {
          id: listBox
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 6
          color: Root.Theme.background
          clip: true

          ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4
            clip: true
            model: server.trackedNotifications

            delegate: Item {
              width: list.width
              height: 52

              Rectangle {
                id: rowBg
                anchors.fill: parent
                radius: 6
                color: rowArea.containsMouse ? Root.Theme.surfaceHover : Root.Theme.surface

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 6
                  spacing: 8

                  Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    Layout.alignment: Qt.AlignVCenter
                    radius: 5
                    color: Root.Theme.overlay

                    Image {
                      id: rowIcon
                      anchors.centerIn: parent
                      visible: source != ""
                      source: Root.NotificationCenter.iconSource(modelData)
                      sourceSize.width: 16
                      sourceSize.height: 16
                    }

                    Text {
                      anchors.centerIn: parent
                      visible: rowIcon.source == ""
                      text: Root.NotificationCenter.iconLetter(modelData)
                      color: Root.Theme.textMuted
                      font.family: Root.Theme.fontFamily
                      font.pixelSize: 12
                      font.bold: true
                    }
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                      text: modelData != null ? modelData.appName : ""
                      visible: text != ""
                      color: Root.Theme.textMuted
                      font.family: Root.Theme.fontFamily
                      font.pixelSize: 10
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }

                    Text {
                      text: modelData != null ? modelData.summary : ""
                      visible: text != ""
                      color: Root.Theme.text
                      font.family: Root.Theme.fontFamily
                      font.pixelSize: 12
                      font.bold: true
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }

                    Text {
                      text: modelData != null ? modelData.body : ""
                      visible: text != ""
                      color: Root.Theme.textMuted
                      font.family: Root.Theme.fontFamily
                      font.pixelSize: 11
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }
                  }

                  Components.Button {
                    text: "\u00d7"
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    Layout.alignment: Qt.AlignVCenter
                    visible: rowArea.containsMouse
                    onClicked: {
                      if (modelData != null) modelData.dismiss()
                    }
                  }
                }

                MouseArea {
                  id: rowArea
                  anchors.fill: parent
                  hoverEnabled: true
                  acceptedButtons: Qt.NoButton
                }
              }
            }

            add: Transition {
              NumberAnimation {
                properties: "opacity"
                from: 0
                to: 1
                duration: Root.Config.notificationAnimDuration
                easing.type: Easing.OutCubic
              }
            }
          }

          Text {
            anchors.centerIn: parent
            visible: list.count == 0
            text: "No notifications"
            color: Root.Theme.textMuted
            font.family: Root.Theme.fontFamily
            font.pixelSize: 12
          }
        }
      }
    }
  }
}