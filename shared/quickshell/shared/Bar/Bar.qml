import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
  id: bar
  property var modelData

  screen: modelData
  anchors {
    top: true
    left: true
    right: true
  }
  color: "transparent"
  implicitHeight: content.implicitHeight + 4

  RowLayout {
    id: content
    anchors {
      left: parent.left
      right: parent.right
      top: parent.top
      topMargin: 2
      leftMargin: 8
      rightMargin: 8
      bottomMargin: 0
    }
    spacing: 8

    // Spacer
    Item {
      Layout.fillWidth: true
    }

    // Clock on the right
    Clock {
      Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    }

    // Volume control
    Volume {
      panelWindow: bar
      Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    }

    // Brightness control
    Brightness {
      panelWindow: bar
      Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    }

    // Night mode (keyboard backlight + gamma)
    Night {
      panelWindow: bar
      Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    }

    // Battery indicator
    Battery {
      showPercentage: true
      Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    }

    // Power menu button
    Power {
      panelWindow: bar
      Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
    }
  }
}