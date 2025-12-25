import Quickshell
import QtQuick
import ".." as Root

Text {
  id: root
  text: clock.time
  color: Root.Theme.text
  font.pixelSize: 14
  font.family: Root.Theme.fontFamily

  SystemClock {
    id: clock
    property string time: ""

    precision: SystemClock.Minutes

    Component.onCompleted: {
      updateTime();
    }

    function updateTime() {
      const now = new Date();
      let hours24 = now.getHours();
      let hours12 = hours24 === 0 ? 12 : (hours24 > 12 ? hours24 - 12 : hours24);
      const hours = hours12.toString().padStart(2, '0');
      const minutes = now.getMinutes().toString().padStart(2, '0');
      const ampm = hours24 >= 12 ? 'PM' : 'AM';
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      time = days[now.getDay()] + " " + 
             months[now.getMonth()] + " " + 
             now.getDate() + " " + 
             hours + ":" + minutes + " " + ampm;
    }

    onTimeChanged: {
      updateTime();
    }
  }
}
