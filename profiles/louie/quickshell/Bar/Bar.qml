import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import ".." as Root

PanelWindow {
  id: bar
  property var modelData

  screen: modelData
  anchors {
    top: true
    left: true
    right: true
  }
  exclusiveZone: 0
  color: "transparent"
  implicitHeight: barContainer.implicitHeight + 8
  property bool _entering: false
  property bool _mouseActive: false

  mask: Region {
    item: maskItem
  }

  Item {
    id: maskItem
    anchors {
      top: parent.top
      right: parent.right
    }
    width: (Root.Config.barVisible || bar._mouseActive) ? bar.width : 4
    height: (Root.Config.barVisible || bar._mouseActive) ? bar.height : 4
    visible: false
  }

  MouseArea {
    id: detectionArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton

    onEntered: {
      forceHideTimer.stop()
      hideTimer.stop()
      if (!bar._mouseActive && !Root.Config.barVisible) {
        bar._entering = true
        bar._mouseActive = true
      }
    }

    onExited: {
      if (bar._mouseActive) {
        hideTimer.start()
      }
    }
  }

  Timer {
    id: hideTimer
    interval: 1200
    onTriggered: {
      if (!detectionArea.containsMouse && bar._mouseActive) {
        bar._entering = false
        bar._mouseActive = false
      }
    }
  }

  Timer {
    id: forceHideTimer
    interval: 5000
    onTriggered: {
      bar._entering = false
      Root.Config.barVisible = false
    }
  }

  IpcHandler {
    target: "bar"

    function toggle(): void {
      if (Root.Config.barVisible || bar._mouseActive) {
        forceHideTimer.stop()
        hideTimer.stop()
        bar._entering = false
        bar._mouseActive = false
        Root.Config.barVisible = false
      } else {
        bar._entering = true
        Root.Config.barVisible = true
        forceHideTimer.start()
      }
    }
  }

  Item {
    anchors {
      left: parent.left
      right: parent.right
      top: parent.top
      bottom: parent.bottom
    }
    clip: true

    Rectangle {
      id: barContainer
      anchors {
        left: parent.left
        right: parent.right
        leftMargin: 8
        rightMargin: 8
      }
      y: (Root.Config.barVisible || bar._mouseActive) ? 8 : -(barContainer.implicitHeight + 8)

      Behavior on y {
        NumberAnimation {
          duration: bar._entering ? 400 : 350
          easing.type: Easing.OutQuart
        }
      }

      color: Root.Theme.surface
      border.width: 2
      border.color: Root.Theme.overlay
      radius: 4
      implicitHeight: contentRow.implicitHeight + 12

      RowLayout {
        id: contentRow
        anchors {
          left: parent.left
          right: parent.right
          top: parent.top
          leftMargin: 8
          rightMargin: 8
          topMargin: 6
          bottomMargin: 6
        }
        spacing: 6

        Item {
          Layout.fillWidth: true
        }

        Repeater {
          model: {
            var items = [];
            if (Root.Config.timeEnabled) {
              items.push({ widget: "time", position: Root.Config.timePosition });
            }
            items.sort(function(a, b) { return a.position - b.position; });
            return items;
          }

          Loader {
            sourceComponent: {
              switch (modelData.widget) {
                case "time": return timeComp;
                default: return null;
              }
            }
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
          }
        }

        Component {
          id: timeComp
          Time {}
        }
      }
    }
  }
}
