import QtQuick
import ".." as Root

Rectangle {
  id: root

  property alias text: label.text
  property alias source: icon.source
  property bool active: false
  signal clicked()

  readonly property bool hasIcon: source != ""

  implicitWidth: 24
  implicitHeight: 24
  radius: 6
  border.width: 1
  border.color: mouseArea.containsMouse
    ? Qt.lighter(Root.Theme.primary, 1.3)
    : (active ? Root.Theme.accent : Root.Theme.overlay)
  color: mouseArea.containsMouse
    ? Qt.lighter(Root.Theme.primary, 1.15)
    : (active ? Root.Theme.accent : Root.Theme.primary)

  Behavior on color { ColorAnimation { duration: 100 } }
  Behavior on border.color { ColorAnimation { duration: 100 } }

  Text {
    id: label
    anchors.centerIn: parent
    visible: !root.hasIcon
    color: active ? Root.Theme.accentContent : Root.Theme.primaryContent
    font.pixelSize: 11
    font.family: Root.Theme.fontFamily
  }

  Image {
    id: icon
    anchors.centerIn: parent
    visible: root.hasIcon
    sourceSize.width: 16
    sourceSize.height: 16
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
