import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    property string fileName
    property string filePath
    property bool isDir
    property string iconPath: ""
    property bool isSelected
    property bool renaming: false
    property color renameBgColor: "#1a1a2e"

    signal clicked(var mouse)
    signal doubleClicked
    signal rightClicked(var mouse)
    signal renameCommitted(string newName)
    signal renameCancelled

    width: 280
    height: 80
    color: isSelected
        ? Qt.rgba(0.27, 0.51, 0.9, 0.4)
        : (hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent")
    border.color: isSelected ? Qt.rgba(0.39, 0.63, 1.0, 0.6) : "transparent"
    border.width: isSelected ? 1 : 0
    radius: 6

    property bool hovered: false

    RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 10

        Item {
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            Layout.alignment: Qt.AlignVCenter

            Image {
                id: iconImage
                anchors.fill: parent
                source: root.iconPath ? "file://" + root.iconPath : ""
                visible: root.iconPath !== "" && status !== Image.Error
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 48
                sourceSize.height: 48

                onStatusChanged: {
                    if (status === Image.Error) {
                        console.log("Icon failed to load:", source);
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                text: isDir ? "📁" : "📄"
                font.pixelSize: 34
                visible: root.iconPath === "" || iconImage.status === Image.Error
            }
        }

        Label {
            id: nameLabel
            text: root.fileName
            textFormat: Text.PlainText
            color: "white"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            font.weight: Font.Medium
            font.pixelSize: 15
            style: Text.Outline
            styleColor: "black"
            visible: !root.renaming
        }

        TextField {
            id: renameField
            text: root.fileName
            color: "white"
            font.pixelSize: 15
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            visible: root.renaming

            background: Rectangle {
                color: root.renameBgColor
                border.color: Qt.rgba(100, 160, 255, 0.8)
                border.width: 1
                radius: 4
            }

            onVisibleChanged: {
                if (visible) {
                    forceActiveFocus();
                    var dotIdx = text.lastIndexOf(".");
                    select(0, dotIdx > 0 ? dotIdx : text.length);
                }
            }

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    event.accepted = true;
                    root.renameCommitted(text.trim());
                } else if (event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    root.renameCancelled();
                }
            }

            onActiveFocusChanged: {
                if (!activeFocus && root.renaming) {
                    root.renameCommitted(text.trim());
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onEntered: root.hovered = true
        onExited: root.hovered = false

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                root.rightClicked(mouse);
            } else {
                root.clicked(mouse);
            }
        }

        onDoubleClicked: root.doubleClicked()
    }
}
