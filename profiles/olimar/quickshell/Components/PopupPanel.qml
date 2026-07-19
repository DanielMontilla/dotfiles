import QtQuick
import ".." as Root

Panel {
  id: root

  property bool open: false

  scale: open ? 1 : Root.Config.popupScaleClosed
  opacity: open ? 1 : 0
  transformOrigin: Item.TopRight

  Behavior on scale {
    NumberAnimation {
      duration: Root.Config.popupAnimDuration
      easing.type: Easing.OutBack
    }
  }
  Behavior on opacity {
    NumberAnimation {
      duration: Root.Config.popupAnimDuration
      easing.type: Easing.OutCubic
    }
  }
}
