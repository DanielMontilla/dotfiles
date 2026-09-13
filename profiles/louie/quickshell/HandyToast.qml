import Quickshell
import Quickshell.Io
import QtQuick

PanelWindow {
  id: root
  property var modelData
  property int state: 0

  readonly property bool recording: state === 1
  readonly property bool thinking: state === 2

  screen: modelData
  anchors {
    bottom: true
    left: true
  }
  margins {
    bottom: 24
    left: 24
  }
  exclusiveZone: 0
  color: "transparent"
  visible: state !== 0
  implicitWidth: content.width + 2
  implicitHeight: content.height + 2

  Process {
    id: stateProc
    command: ["sh", "-c", "cat ~/.cache/handy-recording 2>/dev/null || echo 0"]
    stdout: StdioCollector {
      onStreamFinished: root.state = parseInt(this.text.trim()) || 0
    }
  }

  Timer {
    interval: 300
    running: true
    repeat: true
    onTriggered: stateProc.running = true
  }

  Rectangle {
    id: content
    anchors.centerIn: parent
    width: row.width + 24
    height: 34
    radius: Theme.radius
    color: Theme.surface
    border.color: root.recording ? Theme.accent : Theme.textMuted
    border.width: 1
    scale: root.recording || root.thinking ? 1 : 0.85
    transformOrigin: Item.BottomLeft

    Behavior on scale {
      NumberAnimation {
        duration: 150
        easing.type: Easing.OutCubic
      }
    }

    Behavior on border.color { ColorAnimation { duration: 150 } }

    Row {
      id: row
      anchors.centerIn: parent
      spacing: 8

      Item {
        width: 16
        height: 16
        anchors.verticalCenter: parent.verticalCenter

        // Recording: mic icon with red glow bulb
        Item {
          anchors.fill: parent
          visible: root.recording

          Rectangle {
            anchors.centerIn: parent
            width: 18
            height: 18
            radius: 9
            color: Theme.accent
            opacity: 0.2
          }

          Image {
            anchors.centerIn: parent
            source: "assets/mic.svg"
            sourceSize.width: 14
            sourceSize.height: 14
          }
        }

        // Transcribing: spinner
        Canvas {
          id: spinner
          anchors.centerIn: parent
          width: 14
          height: 14
          visible: root.thinking
          property color stroke: Theme.accent

          onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.beginPath()
            ctx.arc(width / 2, height / 2, width / 2 - 2, 0, Math.PI * 1.4, false)
            ctx.strokeStyle = spinner.stroke
            ctx.lineWidth = 2
            ctx.lineCap = "round"
            ctx.stroke()
          }

          NumberAnimation on rotation {
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
            running: root.thinking
          }
        }
      }

      Text {
        text: root.recording ? "REC" : "Transcribing…"
        color: root.recording ? Theme.accent : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}