import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import ".." as Root
import "../Components" as Components

Rectangle {
  id: root

  property Notification notification

  readonly property bool critical: notification != null && notification.urgency == NotificationUrgency.Critical
  readonly property color accentColor: notification == null ? Root.Theme.primary
    : (critical ? Root.Theme.danger
      : (notification.urgency == NotificationUrgency.Low ? Root.Theme.secondary : Root.Theme.primary))

  readonly property int timeout: {
    if (notification == null || critical) return 0
    if (notification.expireTimeout > 0) return Math.min(notification.expireTimeout, Root.Config.notificationMaxDuration)
    return Root.Config.notificationDuration
  }

  property bool hovered: false
  property bool expired: false
  signal collapsed()

  height: expired ? 0 : content.implicitHeight + 16
  clip: true
  opacity: expired ? 0 : 1

  Behavior on height {
    NumberAnimation {
      duration: Root.Config.notificationAnimDuration
      easing.type: Easing.OutCubic
    }
  }
  Behavior on opacity {
    NumberAnimation {
      duration: Root.Config.notificationAnimDuration
      easing.type: Easing.OutCubic
    }
  }

  color: Root.Theme.surface
  border.color: Root.Theme.overlay
  border.width: 2
  radius: Root.Theme.radius

  Rectangle {
    anchors {
      left: parent.left
      top: parent.top
      bottom: parent.bottom
    }
    width: 3
    radius: 2
    color: accentColor
  }

  HoverHandler {
    onHoveredChanged: root.hovered = hovered
  }

  RowLayout {
    id: content
    x: 14
    y: 8
    width: root.width - 24
    spacing: 10

    Rectangle {
      Layout.preferredWidth: 34
      Layout.preferredHeight: 34
      Layout.alignment: Qt.AlignTop
      radius: 6
      color: Root.Theme.overlay

      Image {
        id: iconImage
        anchors.centerIn: parent
        visible: source != ""
        source: notification != null ? Root.NotificationCenter.iconSource(notification) : ""
        sourceSize.width: 20
        sourceSize.height: 20
      }

      Text {
        anchors.centerIn: parent
        visible: iconImage.source == ""
        text: notification != null ? Root.NotificationCenter.iconLetter(notification) : "?"
        color: Root.Theme.textMuted
        font.family: Root.Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 2

      Text {
        text: notification != null ? notification.appName : ""
        visible: text != ""
        color: Root.Theme.textMuted
        font.family: Root.Theme.fontFamily
        font.pixelSize: 11
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Text {
        text: notification != null ? notification.summary : ""
        visible: text != ""
        color: Root.Theme.text
        font.family: Root.Theme.fontFamily
        font.pixelSize: 13
        font.bold: true
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Text {
        text: notification != null ? notification.body : ""
        visible: text != ""
        color: Root.Theme.textMuted
        font.family: Root.Theme.fontFamily
        font.pixelSize: 12
        wrapMode: Text.Wrap
        maximumLineCount: 3
        elide: Text.ElideRight
        Layout.fillWidth: true
      }
    }

    Components.Button {
      text: "\u00d7"
      Layout.preferredWidth: 22
      Layout.preferredHeight: 22
      Layout.alignment: Qt.AlignTop
      visible: root.hovered
      onClicked: {
        if (notification != null) notification.dismiss()
      }
    }
  }

  Timer {
    id: expireTimer
    interval: root.timeout
    running: notification != null && root.timeout > 0 && !root.hovered && !root.expired
    onTriggered: {
      root.expired = true
      root.collapsed()
    }
  }

  Connections {
    target: notification
    function onExpireTimeoutChanged() { expireTimer.restart() }
    function onUrgencyChanged() { expireTimer.restart() }
  }
}