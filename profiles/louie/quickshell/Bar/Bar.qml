import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import ".." as Root
import "../Components" as Components

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
  property int popupOffset: 2
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
    width: (Root.Config.barVisible || bar._mouseActive || Root.Config.popupActive) ? bar.width : 4
    height: (Root.Config.barVisible || bar._mouseActive || Root.Config.popupActive) ? bar.height : 4
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
        if (Root.Config.popupActive) {
          hideTimer.restart()
          return
        }
        bar._entering = false
        bar._mouseActive = false
        Root.Config.popupActive = false
        Root.Config.popupMouseInside = false
      }
    }
  }

  Timer {
    id: forceHideTimer
    interval: 5000
    onTriggered: {
      if (Root.Config.popupActive) {
        forceHideTimer.restart()
        return
      }
      bar._entering = false
      Root.Config.barVisible = false
      Root.Config.popupActive = false
      Root.Config.popupMouseInside = false
    }
  }

  IpcHandler {
    target: "bar"

    function toggle(): void {
      if (bar._mouseActive || Root.Config.popupActive) return
      if (Root.Config.barVisible) {
        forceHideTimer.stop()
        hideTimer.stop()
        bar._entering = false
        bar._mouseActive = false
        Root.Config.barVisible = false
        Root.Config.popupActive = false
        Root.Config.popupMouseInside = false
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

    Components.Panel {
      id: barContainer
      anchors {
        left: parent.left
        right: parent.right
        leftMargin: 8
        rightMargin: 8
      }
      y: (Root.Config.barVisible || bar._mouseActive || Root.Config.popupActive) ? 8 : -(barContainer.implicitHeight + 8)

      Behavior on y {
        NumberAnimation {
          duration: bar._entering ? 400 : 350
          easing.type: Easing.OutQuart
        }
      }
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
            if (Root.Config.volumeEnabled) {
              items.push({ widget: "volume", position: Root.Config.volumePosition });
            }
            items.sort(function(a, b) { return a.position - b.position; });
            return items;
          }

          Loader {
            sourceComponent: {
              switch (modelData.widget) {
                case "time": return timeComp;
                case "volume": return volumeComp;
                default: return null;
              }
            }
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            onLoaded: {
              if (modelData.widget === "volume") {
                item.panelWindow = bar
              }
            }
          }
        }

        Component {
          id: timeComp
          Time {}
        }

        Component {
          id: volumeComp
          Volume {}
        }
      }
    }
  }
}
