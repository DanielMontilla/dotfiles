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

  readonly property bool displayEnabled: false
  readonly property int displayPosition: 2
  readonly property real displayStep: 0.05

  readonly property bool batteryEnabled: true
  readonly property int batteryPosition: 2

  readonly property bool powerEnabled: true
  readonly property int powerPosition: 3

  readonly property int displayDim: 15
  readonly property int displayLow: 40
  readonly property int displayMid: 65

  property string focusedScreenName: ""

  readonly property int popupAnimDuration: 300
  readonly property real popupScaleClosed: 0.85

  // --- Display / brightness shared state (populated by the Display.qml instances) ---

  // Detected DDC bus numbers
  property var ddcBuses: []
  property string brightnessBackend: ""
  property string backlightDevice: ""

  // Brightness 0-100
  property int brightnessPercent: 100
  property int previousBrightnessPercent: 100

  // Per-bus brightness max values (keyed by bus number)
  property var brightnessMaxByBus: ({})

  // While we are actively writing brightness (poll readings from our own write
  // are ignored instead of being treated as external changes)
  property bool brightnessSettingInFlight: false

  // Pending brightness value to apply when the current write completes
  property int pendingBrightness: -1

  // Warmth state
  property bool warmthEnabled: false
  property int warmth: 50
  property var gainBase: ({})
  property var gainMax: ({})
  property bool gainsLoaded: false
}
