import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

RowLayout {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 30
    spacing: 4

    property alias text: filterField.text
    property int currentPage: 0
    property color fgColor: "white"
    property string fontFamily: "sans-serif"

    signal escapePressed()
    signal upPressed()
    signal downPressed()
    signal leftPressed()
    signal rightPressed()
    signal returnPressed()
    signal pageToggled()

    function forceFocus() { filterField.forceActiveFocus() }

    TextField {
        id: filterField
        Layout.fillWidth: true
        Layout.preferredHeight: 30
        placeholderText: "Filter..."
        color: root.fgColor
        font.family: root.fontFamily
        horizontalAlignment: Text.AlignHCenter
        cursorDelegate: Item { }
        background: Rectangle { color: "transparent"; border.color: "transparent"; border.width: 0 }
        
        Keys.onEscapePressed: root.escapePressed()
        Keys.onUpPressed: root.upPressed()
        Keys.onDownPressed: root.downPressed()
        Keys.onLeftPressed: root.leftPressed()
        Keys.onRightPressed: root.rightPressed()
        Keys.onReturnPressed: root.returnPressed()
    }

    Rectangle {
        Layout.preferredWidth: filterField.height
        Layout.preferredHeight: filterField.height
        color: "transparent"
        radius: 4
        Text {
            anchors.centerIn: parent
            text: root.currentPage === 0 ? "📌" : "🗒"
            color: root.fgColor
            font.family: root.fontFamily
            font.pointSize: 14
        }
        MouseArea { anchors.fill: parent; onClicked: root.pageToggled() }
    }
}
