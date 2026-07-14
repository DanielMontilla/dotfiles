import Quickshell
import QtQuick
import QtQuick.Layouts
import ".." as Root

Item {
  id: root
  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  property string day: ""
  property string month: ""
  property string date: ""
  property string hours: ""
  property string minutes: ""
  property string seconds: ""
  property string ampm: ""

  Timer {
    id: updateTimer
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: updateTime()
  }

  function ordinal(n) {
    const s = ["th", "st", "nd", "rd"];
    const v = n % 100;
    return s[(v - 20) % 10] || s[v] || s[0];
  }

  function updateTime() {
    const now = new Date();
    let h = now.getHours();
    root.ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    h = h ? h : 12;
    root.hours = h.toString();
    root.minutes = now.getMinutes().toString().padStart(2, '0');
    root.seconds = now.getSeconds().toString().padStart(2, '0');
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    root.day = days[now.getDay()];
    root.month = months[now.getMonth()];
    root.date = now.getDate() + ordinal(now.getDate());
  }

  RowLayout {
    id: row
    spacing: 6

    Rectangle {
      color: Root.Theme.primary
      radius: 6
      implicitWidth: dateRow.implicitWidth + 12
      Layout.preferredHeight: 24

      RowLayout {
        id: dateRow
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 6

        Text {
          text: root.day
          color: Root.Theme.primaryContent
          font.pixelSize: 12
          font.family: Root.Theme.fontFamily
          font.weight: Font.Bold
          verticalAlignment: Text.AlignVCenter
          Layout.fillHeight: true
          topPadding: 2
        }
        Text {
          text: "·"
          color: Root.Theme.secondary
          font.pixelSize: 12
          font.family: Root.Theme.fontFamily
          font.weight: Font.Bold
          verticalAlignment: Text.AlignVCenter
          Layout.fillHeight: true
          topPadding: 2
        }
        Text {
          text: root.month + " " + root.date
          color: Root.Theme.primaryContent
          font.pixelSize: 12
          font.family: Root.Theme.fontFamily
          font.weight: Font.Bold
          verticalAlignment: Text.AlignVCenter
          Layout.fillHeight: true
          topPadding: 2
        }
      }
    }

    Rectangle {
      Layout.alignment: Qt.AlignVCenter
      Layout.preferredWidth: 1
      Layout.preferredHeight: row.implicitHeight - 4
      color: Root.Theme.overlay
    }

    Rectangle {
      color: Root.Theme.primary
      radius: 6
      implicitWidth: timeRow.implicitWidth + 12
      Layout.preferredHeight: 24

      RowLayout {
        id: timeRow
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 4

        Text {
          text: root.hours
          color: Root.Theme.primaryContent
          font.pixelSize: 12
          font.family: Root.Theme.fontFamily
          font.weight: Font.Bold
          verticalAlignment: Text.AlignVCenter
          Layout.fillHeight: true
          topPadding: 2
        }
        Text {
          text: ":"
          color: Root.Theme.secondary
          font.pixelSize: 12
          font.family: Root.Theme.fontFamily
          font.weight: Font.Bold
          verticalAlignment: Text.AlignVCenter
          Layout.fillHeight: true
          topPadding: 2
        }
        Text {
          text: root.minutes
          color: Root.Theme.primaryContent
          font.pixelSize: 12
          font.family: Root.Theme.fontFamily
          font.weight: Font.Bold
          verticalAlignment: Text.AlignVCenter
          Layout.fillHeight: true
          topPadding: 2
        }
        Text {
          text: ":"
          color: Root.Theme.secondary
          font.pixelSize: 12
          font.family: Root.Theme.fontFamily
          font.weight: Font.Bold
          verticalAlignment: Text.AlignVCenter
          Layout.fillHeight: true
          topPadding: 2
        }
        Text {
          text: root.seconds
          color: Root.Theme.primaryContent
          font.pixelSize: 12
          font.family: Root.Theme.fontFamily
          font.weight: Font.Bold
          verticalAlignment: Text.AlignVCenter
          Layout.fillHeight: true
          topPadding: 2
        }
        Text {
          text: "·"
          color: Root.Theme.secondary
          font.pixelSize: 12
          font.family: Root.Theme.fontFamily
          font.weight: Font.Bold
          verticalAlignment: Text.AlignVCenter
          Layout.fillHeight: true
          topPadding: 2
        }
        Text {
          text: root.ampm
          color: Root.Theme.primaryContent
          font.pixelSize: 12
          font.family: Root.Theme.fontFamily
          font.weight: Font.Bold
          verticalAlignment: Text.AlignVCenter
          Layout.fillHeight: true
          topPadding: 2
        }
      }
    }
  }
}
