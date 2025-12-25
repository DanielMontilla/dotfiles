import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".." as Root

Item {
  id: root
  property var panelWindow

  property bool menuOpen: false
  // Separate property to control popup visibility (delayed on close for exit animation)
  property bool popupVisible: false

  // Animation duration constant
  readonly property int animDuration: 250

  // Show immediately when opening, delay hide for exit animation
  onMenuOpenChanged: {
    if (menuOpen) {
      hideTimer.stop()  // Cancel pending hide if reopening
      popupVisible = true
      autoCloseTimer.start()  // Start auto-close countdown
    } else {
      autoCloseTimer.stop()
      hideTimer.start()
    }
  }

  // Delay hiding popup until exit animation completes
  Timer {
    id: hideTimer
    interval: animDuration + 50
    onTriggered: popupVisible = false
  }

  // Auto-close if mouse doesn't enter within 5 seconds
  Timer {
    id: autoCloseTimer
    interval: 5000
    onTriggered: {
      if (!popup.mouseEntered) {
        menuOpen = false
      }
    }
  }

  implicitWidth: powerButton.width
  implicitHeight: powerButton.height

  // Reusable menu item component
  component MenuItem: Rectangle {
    id: menuItem
    property string iconSource
    property string label
    property int index: 0

    signal triggered

    Layout.fillWidth: true
    height: 36
    radius: 6
    color: itemArea.containsMouse ? Root.Theme.surfaceHover : "transparent"

    // Animate opacity only (simpler, no layout shift)
    opacity: menuOpen ? 1 : 0

    Behavior on opacity {
      NumberAnimation {
        duration: 250
        easing.type: Easing.OutCubic
      }
    }

    Behavior on color {
      ColorAnimation { duration: 100 }
    }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 12
      anchors.rightMargin: 12
      spacing: 10

      Image {
        source: menuItem.iconSource
        sourceSize.width: 16
        sourceSize.height: 16
        Layout.preferredWidth: 16
        Layout.preferredHeight: 16
      }

      Text {
        text: menuItem.label
        color: Root.Theme.text
        font.pixelSize: 13
        font.family: Root.Theme.fontFamily
        Layout.fillWidth: true
      }
    }

    MouseArea {
      id: itemArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: menuItem.triggered()
    }
  }

  // Power button
  Rectangle {
    id: powerButton
    width: 24
    height: 24
    radius: 6
    color: buttonArea.containsMouse ? Root.Theme.surfaceHover : (menuOpen ? Root.Theme.surface : "transparent")

    Behavior on color {
      ColorAnimation { duration: 100 }
    }

    Image {
      anchors.centerIn: parent
      source: "../assets/power-button.svg"
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

  // Popover menu
  PopupWindow {
    id: popup
    anchor {
      window: panelWindow
      rect.x: panelWindow.width - menuContent.width - 8
      rect.y: powerButton.height + 12
      edges: Edges.Top | Edges.Left
    }

    visible: popupVisible

    implicitWidth: menuContent.width
    implicitHeight: menuContent.height

    color: "transparent"

    // Track hover state
    property bool mouseEntered: false

    onVisibleChanged: {
      if (!visible) {
        mouseEntered = false
      }
    }

    Rectangle {
      id: menuContent
      width: 160
      height: menuColumn.implicitHeight + 16
      radius: 8
      color: Root.Theme.background
      border.color: Root.Theme.surface
      border.width: 1
      clip: true

      // Animate menu appearance
      scale: menuOpen ? 1 : 0.95
      opacity: menuOpen ? 1 : 0
      transformOrigin: Item.TopRight

      Behavior on scale {
        NumberAnimation {
          duration: 250
          easing.type: Easing.OutCubic
        }
      }
      Behavior on opacity {
        NumberAnimation {
          duration: 250
          easing.type: Easing.OutCubic
        }
      }

      // Hover detection using HoverHandler (doesn't block clicks)
      HoverHandler {
        id: menuHover
        onHoveredChanged: {
          if (hovered) {
            popup.mouseEntered = true
            closeTimer.stop()
            autoCloseTimer.stop()  // Cancel auto-close once mouse enters
          } else if (popup.mouseEntered) {
            // Small delay before closing to avoid accidental closes
            closeTimer.start()
          }
        }
      }

      // Timer to close menu after mouse leaves
      Timer {
        id: closeTimer
        interval: 300
        onTriggered: menuOpen = false
      }

      // Handle keyboard - focus the content and listen for Escape
      focus: menuOpen
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
          menuOpen = false
          event.accepted = true
        }
      }

      ColumnLayout {
        id: menuColumn
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        MenuItem {
          index: 0
          iconSource: "../assets/power-off.svg"
          label: "Power Off"
          onTriggered: {
            menuOpen = false
            Quickshell.execDetached(["sh", "-c", "systemctl poweroff || loginctl poweroff"])
          }
        }

        MenuItem {
          index: 1
          iconSource: "../assets/restart.svg"
          label: "Reboot"
          onTriggered: {
            menuOpen = false
            Quickshell.execDetached(["sh", "-c", "systemctl reboot || loginctl reboot"])
          }
        }

        MenuItem {
          index: 2
          iconSource: "../assets/sleep.svg"
          label: "Suspend"
          onTriggered: {
            menuOpen = false
            Quickshell.execDetached(["sh", "-c", "systemctl suspend || loginctl suspend"])
          }
        }

        // Separator
        Rectangle {
          Layout.fillWidth: true
          Layout.topMargin: 4
          Layout.bottomMargin: 4
          height: 1
          color: Root.Theme.surface
          opacity: menuOpen ? 1 : 0
          Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
          }
        }

        MenuItem {
          index: 3
          iconSource: "../assets/log-out.svg"
          label: "Log Out"
          onTriggered: {
            menuOpen = false
            Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
          }
        }
      }
    }
  }
}
