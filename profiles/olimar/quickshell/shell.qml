import Quickshell
import Quickshell.Wayland
import QtQuick

import "./Bar" as Bar

ShellRoot {
  Variants {
    model: Quickshell.screens

    Item {
      id: variant
      property var modelData

      Bar.Bar {
        modelData: variant.modelData
      }

      Bar.Notifications {
        screenRef: variant.modelData
      }
    }
  }
}
