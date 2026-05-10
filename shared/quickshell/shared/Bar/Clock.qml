import Quickshell
import QtQuick
import ".." as Root

Text {
  id: root
  text: root.time
  color: Root.Theme.text
  font.pixelSize: 14
  font.family: Root.Theme.fontFamily

  property string time: ""

  Timer {
    id: updateTimer
    interval: 5000 // Update every minute
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: updateTime()
  }

  function updateTime() {
    const now = new Date();
    let hours = now.getHours();
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    hours = hours ? hours : 12; // 0 should be 12
    const hoursStr = hours.toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    time = days[now.getDay()] + " " + 
           months[now.getMonth()] + " " + 
           now.getDate() + " " + 
           hoursStr + ":" + minutes + " " + ampm;
  }
}
