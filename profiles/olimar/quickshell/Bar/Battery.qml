import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import ".." as Root

Item {
  id: root
  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight
  property bool showPercentage: true

  // Battery state from UPower
  readonly property var battery: UPower.displayDevice
  readonly property bool isReady: battery && battery.ready && battery.percentage !== undefined
  readonly property real percent: isReady ? battery.percentage * 100 : 0
  readonly property bool charging: isReady && battery.state === UPowerDeviceState.Charging

  // Hide if no battery detected
  visible: isReady

  function getIconSource(): string {
    if (charging) return "../assets/battery-charging.svg"
    if (percent >= 80) return "../assets/battery-full.svg"
    if (percent >= 30) return "../assets/battery-medium.svg"
    return "../assets/battery-low.svg"
  }

  function getTextColor(): color {
    if (charging) return Root.Theme.successContent
    if (percent < 20) return Root.Theme.dangerContent
    if (percent < 30) return Root.Theme.warningContent
    return Root.Theme.primaryContent
  }

  RowLayout {
    id: row
    spacing: 6

    Rectangle {
      color: Root.Theme.primary
      radius: 6
      implicitWidth: batteryRow.implicitWidth + 12
      Layout.preferredHeight: 24

      RowLayout {
        id: batteryRow
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 4

        Image {
          source: getIconSource()
          sourceSize.width: 14
          sourceSize.height: 14
          Layout.preferredWidth: 14
          Layout.preferredHeight: 14
        }

        Text {
          visible: showPercentage
          text: Math.round(percent) + "%"
          color: getTextColor()
          font.pixelSize: 12
          font.family: Root.Theme.fontFamily
          font.weight: Font.Bold
          verticalAlignment: Text.AlignVCenter
          Layout.fillHeight: true
          topPadding: 2
        }
      }
    }
  }
}
