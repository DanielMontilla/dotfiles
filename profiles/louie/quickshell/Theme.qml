pragma Singleton
import QtQuick

QtObject {
  readonly property color background: "#16101e"
  readonly property color surface: "#2a2038"
  readonly property color surfaceHover: "#3a2a48"
  readonly property color overlay: "#4a3a58"

  readonly property color text: "#e0d0f0"
  readonly property color textMuted: "#9a8aa8"

  readonly property color primary: "#7a9bb5"
  readonly property color primaryContent: "#16101e"
  readonly property color secondary: "#89b4fa"
  readonly property color secondaryContent: "#16101e"
  readonly property color accent: "#b898d0"
  readonly property color accentContent: "#16101e"

  readonly property color backgroundContent: "#e0d0f0"
  readonly property color surfaceContent: "#e0d0f0"
  readonly property color surfaceHoverContent: "#e0d0f0"
  readonly property color overlayContent: "#e0d0f0"

  readonly property color danger: "#d07070"
  readonly property color dangerContent: "#16101e"
  readonly property color warning: "#d0a070"
  readonly property color warningContent: "#16101e"
  readonly property color success: "#80b080"
  readonly property color successContent: "#16101e"

  readonly property string fontFamily: "monospace"
}
