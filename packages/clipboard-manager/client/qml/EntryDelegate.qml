import QtQuick 2.15
import QtQuick.Controls 2.15
import Quickshell

Item {
    id: delegateRoot
    width: parent ? parent.width : 400
    height: 64
    clip: true

    property var entry: ({})
    property bool isCurrent: false
    property color highlightColor: "transparent"
    property color textColor: "white"
    property color commentColor: "gray"
    property string fontFamily: "Iosevka NFM"

    function thumbPath(content) {
        var parts = content.split("/")
        var filename = parts[parts.length - 1]
        var runtime = Quickshell.env("XDG_RUNTIME_DIR")
        if (!runtime) runtime = "/tmp"
        return runtime + "/clipboard-manager/thumbnails/" + filename
    }

    function lineCount(text) {
        if (!text) return 0
        return text.split(/\r\n|\r|\n/).length
    }

    readonly property int contentLineCount: {
        if (entry.type === "text") return lineCount(entry.content)
        if (entry.type === "pinned") return lineCount(entry.text)
        return 0
    }

    Rectangle {
        anchors.fill: parent
        color: isCurrent ? highlightColor : "transparent"
        radius: 4

        Row {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 8

            Image {
                id: thumbImage
                width: 56
                height: 56
                fillMode: Image.PreserveAspectCrop
                source: entry.type === "image" ? thumbPath(entry.content) : ""
                visible: entry.type === "image"
                asynchronous: true
                onStatusChanged: function(status) {
                    if (status === Image.Error) visible = false
                }
            }

            Text {
                id: mainText
                width: parent.width - (entry.type === "image" ? 70 : 10)
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: 2
                color: textColor
                font.family: delegateRoot.fontFamily
                font.pointSize: 11
                textFormat: Text.PlainText
                text: {
                    if (entry.type === "pinned") return entry.text
                    else if (entry.type === "text") return entry.content
                    else if (entry.type === "image") return "🖼️ Image"
                    return ""
                }
            }
        }

        // Bottom‑right info: line count for text, MIME type for image.
        Text {
            id: infoText
            color: commentColor
            font.family: delegateRoot.fontFamily
            font.pointSize: 10   // increased from 8
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 4

            text: {
                if (entry.type === "image" && entry.mimeType)
                    return entry.mimeType
                else if (entry.type === "text" && contentLineCount >= 3)
                    return contentLineCount + " lines"
                else
                    return ""
            }
            visible: text !== ""
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            var listView = delegateRoot.parent
            if (listView && listView.hasOwnProperty("currentIndex")) {
                listView.currentIndex = index
            }
        }
    }
}
