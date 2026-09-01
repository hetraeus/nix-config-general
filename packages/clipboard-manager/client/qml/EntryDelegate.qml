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
    property bool isHovered: false
    property color highlightColor: "transparent"
    property color hoverColor: "#404060"
    property color textColor: "white"
    property color selectedTextColor: "black"
    property color commentColor: "gray"
    property string fontFamily: "Iosevka NFM"

    property bool initialPositionSet: false

    function thumbPath(content) {
        if (!content) return ""
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
        if (!entry) return 0
        if (entry.type === "text") return lineCount(entry.content)
        if (entry.type === "pinned") return lineCount(entry.text)
        return 0
    }

    signal clicked(int index)
    signal activated()
    signal hovered(int index)

    Rectangle {
        anchors.fill: parent
        color: {
            if (isCurrent) return highlightColor
            if (isHovered) return hoverColor
            return "transparent"
        }
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
                source: (entry && entry.type === "image") ? thumbPath(entry.content) : ""
                visible: (entry && entry.type === "image") ? true : false
                asynchronous: true
                onStatusChanged: function(status) {
                    if (status === Image.Error) visible = false
                }
            }

            Text {
                id: mainText
                width: parent.width - ((entry && entry.type === "image") ? 70 : 10)
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: 2
                color: isCurrent ? selectedTextColor : textColor
                font.family: delegateRoot.fontFamily
                font.pointSize: 11
                textFormat: Text.PlainText
                text: {
                    if (!entry) return ""
                    if (entry.type === "pinned") return entry.text
                    else if (entry.type === "text") return entry.content
                    else if (entry.type === "image") return "🖼️ Image"
                    return ""
                }
            }
        }

        Text {
            id: infoText
            color: isCurrent ? selectedTextColor : commentColor
            font.family: delegateRoot.fontFamily
            font.pointSize: 10
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 4

            text: {
                if (!entry) return ""
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
        hoverEnabled: true
        onClicked: {
            delegateRoot.clicked(index)
        }
        onEntered: {
            delegateRoot.hovered(index)
        }
        // onExited is handled by the ListView's outer MouseArea
    }
}
