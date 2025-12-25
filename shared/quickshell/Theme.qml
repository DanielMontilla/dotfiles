pragma Singleton
import QtQuick

QtObject {
  // Base colors
  readonly property color background: "#1e1e2e"
  readonly property color surface: "#313244"
  readonly property color surfaceHover: "#45475a"
  readonly property color overlay: "#6c7086"

  // Text
  readonly property color text: "#cdd6f4"
  readonly property color textMuted: "#6c7086"

  // Accent colors
  readonly property color primary: "#cba6f7"
  readonly property color secondary: "#89b4fa"
  readonly property color accent: "#f38ba8"

  // Semantic colors
  readonly property color danger: "#f38ba8"
  readonly property color warning: "#fab387"
  readonly property color success: "#a6e3a1"

  // Typography
  readonly property string fontFamily: "monospace"
}

