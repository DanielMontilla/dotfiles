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
  property bool popupActive: false
  property bool popupMouseInside: false
  signal closeAllMenus()

  mask: Region {
    item: maskItem
  }

  Item {
    id: maskItem
    anchors {
      top: parent.top
      right: parent.right
    }
    width: (Root.Config.barVisible || bar._mouseActive || bar.popupActive) ? bar.width : 4
    height: (Root.Config.barVisible || bar._mouseActive || bar.popupActive) ? bar.height : 4
    visible: false
  }

  MouseArea {
    id: detectionArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton

    onEntered: {
      Root.Config.focusedScreenName = modelData.name
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
        if (bar.popupActive) {
          hideTimer.restart()
          return
        }
        bar._entering = false
        bar._mouseActive = false
        bar.popupActive = false
        bar.popupMouseInside = false
      }
    }
  }

  Timer {
    id: forceHideTimer
    interval: 5000
    onTriggered: {
      if (bar.popupActive) {
        forceHideTimer.restart()
        return
      }
      bar._entering = false
      Root.Config.barVisible = false
      bar.popupActive = false
      bar.popupMouseInside = false
    }
  }

  IpcHandler {
    target: "bar"

    function toggle(): void {
      if (bar._mouseActive || bar.popupActive) return
      if (Root.Config.barVisible) {
        forceHideTimer.stop()
        hideTimer.stop()
        bar._entering = false
        bar._mouseActive = false
        Root.Config.barVisible = false
        bar.popupActive = false
        bar.popupMouseInside = false
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
      y: (Root.Config.barVisible || bar._mouseActive || bar.popupActive) ? 8 : -(barContainer.implicitHeight + 8)

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
            if (Root.Config.brightnessEnabled) {
              items.push({ widget: "brightness", position: Root.Config.brightnessPosition });
            }
            if (Root.Config.displayEnabled) {
              items.push({ widget: "display", position: Root.Config.displayPosition });
            }
            if (Root.Config.batteryEnabled) {
              items.push({ widget: "battery", position: Root.Config.batteryPosition });
            }
            if (Root.Config.powerEnabled) {
              items.push({ widget: "power", position: Root.Config.powerPosition });
            }
            items.sort(function(a, b) { return a.position - b.position; });
            return items;
          }

          Loader {
            sourceComponent: {
              switch (modelData.widget) {
                case "time": return timeComp;
                case "volume": return volumeComp;
                case "brightness": return brightnessComp;
                case "display": return displayComp;
                case "battery": return batteryComp;
                case "power": return powerComp;
                default: return null;
              }
            }
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            onLoaded: {
              if (modelData.widget === "volume" || modelData.widget === "brightness" || modelData.widget === "display" || modelData.widget === "power") {
                item.panelWindow = bar
                item.bar = bar
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

        Component {
          id: brightnessComp
          Brightness {}
        }

        Component {
          id: displayComp
          Display {}
        }

        Component {
          id: batteryComp
          Battery {}
        }

        Component {
          id: powerComp
          Power {}
        }
      }
    }
  }
}
