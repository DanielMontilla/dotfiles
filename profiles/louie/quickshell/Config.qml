pragma Singleton
import QtQuick

QtObject {
  property bool barVisible: false

  readonly property bool timeEnabled: true
  readonly property int timePosition: 0

  readonly property bool volumeEnabled: true
  readonly property int volumePosition: 1
  readonly property real maxVolume: 1.25
  readonly property real lowVolume: 0.25
  readonly property real midVolume: 0.5
  readonly property real changeInterval: 0.05

  readonly property bool displayEnabled: true
  readonly property int displayPosition: 2
  readonly property real displayStep: 0.05

  readonly property bool powerEnabled: true
  readonly property int powerPosition: 3

  readonly property int displayDim: 15
  readonly property int displayLow: 40
  readonly property int displayMid: 65

  property string focusedScreenName: ""
}
