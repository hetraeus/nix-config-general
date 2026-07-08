import QtQuick
import QtQuick.Controls

Label {
    id: root
    color: "white"
    font.pixelSize: 18
    text: "🕐 " + Qt.formatTime(new Date(), "hh:mm")

    Timer {
        interval: 13000
        running: true
        repeat: true
        onTriggered: root.text = "🕐 " + Qt.formatTime(new Date(), "hh:mm")
    }
} 
