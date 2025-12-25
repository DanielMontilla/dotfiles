import Quickshell
import Quickshell.Hyprland
import QtQuick
import ".." as Root

Row {
  spacing: 2

  Repeater {
    model: 9

    Rectangle {
      id: workspaceButton
      property int workspaceId: index + 1
      property bool isActive: Hyprland.focusedMonitor?.activeWorkspace?.id === workspaceId
      property bool hasWindows: {
        for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
          let ws = Hyprland.workspaces.values[i];
          if (ws.id === workspaceId) {
            return true;
          }
        }
        return false;
      }

      width: 20
      height: 20
      radius: 2
      color: isActive ? Root.Theme.primary : (hasWindows ? Root.Theme.surfaceHover : "transparent")

      Text {
        anchors.centerIn: parent
        text: workspaceId
        color: isActive ? Root.Theme.background : (hasWindows ? Root.Theme.text : Root.Theme.textMuted)
        font.pixelSize: 12
        font.bold: isActive
        font.family: Root.Theme.fontFamily
      }

      MouseArea {
        anchors.fill: parent
        onClicked: Hyprland.dispatch("workspace " + workspaceId)
      }
    }
  }
}
