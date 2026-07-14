pragma Singleton
import QtQuick

QtObject {
  readonly property color background: "#202020"
  readonly property color surface: "#1c1c1c"
  readonly property color surfaceHover: "#181818"
  readonly property color overlay: "#23282e"

  readonly property color text: "#cdcdcd"
  readonly property color textMuted: "#cecfd0"

  readonly property color primary: "#1c4e80"
  readonly property color primaryContent: "#d0dae5"
  readonly property color secondary: "#7c909a"
  readonly property color secondaryContent: "#050708"
  readonly property color accent: "#ea6947"
  readonly property color accentContent: "#130402"

  readonly property color backgroundContent: "#cdcdcd"
  readonly property color surfaceContent: "#cdcdcd"
  readonly property color surfaceHoverContent: "#cdcdcd"
  readonly property color overlayContent: "#cecfd0"

  readonly property color danger: "#ac3e31"
  readonly property color dangerContent: "#f2d8d4"
  readonly property color warning: "#dbae5a"
  readonly property color warningContent: "#110b03"
  readonly property color success: "#6bb187"
  readonly property color successContent: "#040b07"
  readonly property color info: "#0291d5"
  readonly property color infoContent: "#000710"

  readonly property string fontFamily: "monospace"

  readonly property int radius: 8
}
