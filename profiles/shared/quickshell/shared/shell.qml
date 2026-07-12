import Quickshell
import Quickshell.Wayland
import QtQuick

import "./Bar" as Bar

ShellRoot {
  Variants {
    model: Quickshell.screens

    Bar.Bar {
      modelData: modelData
    }
  }
}
