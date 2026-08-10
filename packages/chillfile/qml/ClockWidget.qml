import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Label {
    id: root
    color: "white"
    font.pixelSize: 18
    text: "🕐 " + Qt.formatTime(new Date(), "hh:mm")

    required property var desktop
    property bool hovered: false

    function utcTimeString() {
        var d = new Date();
        var h = String(d.getUTCHours()).padStart(2, "0");
        var m = String(d.getUTCMinutes()).padStart(2, "0");
        return h + ":" + m + " UTC";
    }

    Timer {
        interval: 13000
        running: true
        repeat: true
        onTriggered: root.text = "🕐 " + Qt.formatTime(new Date(), "hh:mm")
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: {
            if (calendarPopup.visible) calendarPopup.close();
            else calendarPopup.open();
        }
    }

    CalendarPopup {
        id: calendarPopup
        desktop: root.desktop
        x: (root.width - width) / 2
        y: -height - 8
    }

    onHoveredChanged: {
        if (hovered) {
            clockTipTimer.start();
        } else {
            clockTipTimer.stop();
            clockTip.visible = false;
        }
    }

    Timer {
        id: clockTipTimer
        interval: 1500
        onTriggered: {
            clockTip.text = root.utcTimeString();
            clockTip.visible = true;
        }
    }

    ToolTip {
        id: clockTip
        text: root.utcTimeString()
        visible: false
        background: Rectangle {
            color: root.desktop.base01
            border.color: Qt.rgba(root.desktop.base04.r, root.desktop.base04.g, root.desktop.base04.b, 0.3)
            border.width: 1
            radius: 4
        }
        contentItem: Label {
            text: clockTip.text
            color: root.desktop.base04
            font.pixelSize: 13
        }
    }
}
