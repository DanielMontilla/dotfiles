import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import ".." as Root

Item {
  id: root

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
    if (charging) return Root.Theme.success
    if (percent < 20) return Root.Theme.danger
    if (percent < 30) return Root.Theme.warning
    return Root.Theme.text
  }

  implicitWidth: batteryRow.implicitWidth
  implicitHeight: batteryRow.implicitHeight

  RowLayout {
    id: batteryRow
    spacing: 4

    Image {
      source: getIconSource()
      sourceSize.width: 16
      sourceSize.height: 16
      Layout.preferredWidth: 16
      Layout.preferredHeight: 16
    }

    Text {
      visible: showPercentage
      text: Math.round(percent) + "%"
      color: getTextColor()
      font.pixelSize: 11
      font.family: Root.Theme.fontFamily
    }
  }
}
