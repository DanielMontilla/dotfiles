import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import ".." as Root

PanelWindow {
  id: root
  property var screenRef

  screen: screenRef
  anchors {
    right: true
    bottom: true
  }
  exclusiveZone: 0
  aboveWindows: true
  focusable: false
  color: "transparent"
  implicitWidth: Root.Config.notificationWidth
  implicitHeight: Math.min(notifList.contentHeight + Root.Config.notificationMargin, Root.Config.notificationMaxHeight)
  visible: false

  property QtObject server: Root.NotificationCenter.server
  property var expiredIds: ({})

  Component.onCompleted: recomputeVisible()

  function markExpired(notification) {
    expiredIds[notification.id] = true
    recomputeVisible()
  }

  function recomputeVisible() {
    var vals = server.trackedNotifications.values
    var active = false
    for (var i = 0; i < vals.length; i++) {
      if (vals[i] != null && !expiredIds[vals[i].id]) {
        active = true
        break
      }
    }
    root.visible = Root.Config.notificationsEnabled && active
  }

  Connections {
    target: server
    function onNotification(notification) {
      if (!notification.transient) notification.tracked = true
      recomputeVisible()
    }
    function onTrackedNotificationsChanged() {
      recomputeVisible()
    }
  }

  Connections {
    target: server.trackedNotifications
    function onValuesChanged() {
      recomputeVisible()
    }
  }

  ListView {
    id: notifList
    anchors {
      right: parent.right
      bottom: parent.bottom
      rightMargin: Root.Config.notificationMargin
      bottomMargin: Root.Config.notificationMargin
    }
    width: Root.Config.notificationWidth
    height: Math.min(contentHeight, Root.Config.notificationMaxHeight)
    interactive: false
    clip: false
    spacing: Root.Config.notificationGap
    model: server.trackedNotifications

    delegate: Item {
      width: Root.Config.notificationWidth
      height: card.height

      NotificationCard {
        id: card
        anchors {
          left: parent.left
          right: parent.right
        }
        notification: modelData
        onCollapsed: root.markExpired(modelData)
      }
    }

    add: Transition {
      NumberAnimation {
        properties: "opacity"
        from: 0
        to: 1
        duration: Root.Config.notificationAnimDuration
        easing.type: Easing.OutCubic
      }
    }

    addDisplaced: Transition {
      NumberAnimation {
        properties: "y"
        duration: Root.Config.notificationAnimDuration
        easing.type: Easing.OutCubic
      }
    }

    removeDisplaced: Transition {
      NumberAnimation {
        properties: "y"
        duration: Root.Config.notificationAnimDuration
        easing.type: Easing.OutCubic
      }
    }

    populate: Transition {
      NumberAnimation {
        properties: "opacity"
        from: 0
        to: 1
        duration: Root.Config.notificationAnimDuration
        easing.type: Easing.OutCubic
      }
    }
  }
}