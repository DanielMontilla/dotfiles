pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

QtObject {
  readonly property NotificationServer server: NotificationServer {
    id: notificationServer
    keepOnReload: false
    bodySupported: true
    bodyMarkupSupported: false
    bodyHyperlinksSupported: false
    bodyImagesSupported: true
    actionsSupported: true
    imageSupported: true
    inlineReplySupported: true
    persistenceSupported: true
  }

  function clearAll() {
    while (server.trackedNotifications.values.length > 0) {
      server.trackedNotifications.values[0].dismiss()
    }
  }

  function iconSource(notification): string {
    if (notification == null) return ""
    if (notification.image != "") return notification.image
    if (notification.appIcon != "") {
      if (notification.appIcon.charAt(0) == "/") return "file://" + notification.appIcon
      return "image://icon/" + notification.appIcon
    }
    return ""
  }

  function iconLetter(notification): string {
    if (notification == null) return "?"
    var name = notification.appName
    if (name == "") name = notification.summary
    if (name == "") name = notification.body
    return name.length > 0 ? name.charAt(0).toUpperCase() : "?"
  }
}