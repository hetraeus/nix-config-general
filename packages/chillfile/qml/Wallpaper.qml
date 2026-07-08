import QtQuick
import Quickshell

Rectangle {
    anchors.fill: parent
    color: "#1a1a2e"
    z: -2

    Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: "file://" + Quickshell.env("HOME") + "/.local/share/wallpaper"
        visible: status === Image.Ready

        onStatusChanged: {
            if (status === Image.Error) {
                var s = source.toString();
                if (s.endsWith("/wallpaper")) {
                    source = "file://" + Quickshell.env("HOME") + "/.local/share/wallpaper.png";
                } else if (s.endsWith(".png")) {
                    source = "file://" + Quickshell.env("HOME") + "/.local/share/wallpaper.jpg";
                } else if (s.endsWith(".jpg")) {
                    source = "file://" + Quickshell.env("HOME") + "/.local/share/wallpaper.jpeg";
                } else if (s.endsWith(".jpeg")) {
                    source = "file://" + Quickshell.env("HOME") + "/.local/share/wallpaper.webp";
                }
            }
        }
    }
}
