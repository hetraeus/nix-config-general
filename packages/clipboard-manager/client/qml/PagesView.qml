import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true

    property int currentPage: 0
    property var historyModel: []
    property var historyFiltered: []
    property var pinnedModel: []
    property var pinnedFiltered: []
    property int selectedIndex: 0
    
    property color bgColor: "#1a1a2e"
    property color selColor: "#008080"
    property color fgColor: "#f0f0f0"
    property color commentColor: "#4a4a4a"
    property string fontFamily: "Iosevka NFM"

    signal historyActivated()
    signal pinnedActivated()
    signal historyClicked(int index)
    signal pinnedClicked(int index)
    signal historyHovered(int index)
    signal pinnedHovered(int index)

    Row {
        id: pagesRow
        width: root.width * 2
        height: root.height
        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
        x: root.currentPage === 0 ? 0 : -root.width

        ListView {
            id: historyList
            clip: true
            width: root.width
            height: root.height
            model: root.historyFiltered
            currentIndex: root.selectedIndex
            delegate: EntryDelegate {
                width: historyList.width; height: 64
                entry: root.historyModel[modelData]
                isCurrent: index === historyList.currentIndex
                highlightColor: root.selColor; textColor: root.fgColor
                selectedTextColor: root.bgColor; commentColor: root.commentColor
                fontFamily: root.fontFamily
                onClicked: function(idx) { root.historyClicked(index) }
                onActivated: root.historyActivated()
                onHovered: function(idx) { root.historyHovered(index) }
            }
            highlight: Rectangle { color: root.selColor; radius: 4 }
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 100
        }

        ListView {
            id: pinnedList
            clip: true
            width: root.width
            height: root.height
            model: root.pinnedFiltered
            currentIndex: root.selectedIndex
            delegate: EntryDelegate {
                width: pinnedList.width; height: 64
                entry: root.pinnedModel[modelData]
                isCurrent: index === pinnedList.currentIndex
                highlightColor: root.selColor; textColor: root.fgColor
                selectedTextColor: root.bgColor; commentColor: root.commentColor
                fontFamily: root.fontFamily
                onClicked: function(idx) { root.pinnedClicked(index) }
                onActivated: root.pinnedActivated()
                onHovered: function(idx) { root.pinnedHovered(index) }
            }
            highlight: Rectangle { color: root.selColor; radius: 4 }
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 100
        }
    }
}
