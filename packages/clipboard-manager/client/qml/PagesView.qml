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
    property int hoveredIndex: -1   // mouse hover only, no scrolling

    property color bgColor: "#1a1a2e"
    property color selColor: "#008080"
    property color hoverColor: "#404060"
    property color fgColor: "#f0f0f0"
    property color commentColor: "#4a4a4a"
    property string fontFamily: "Iosevka NFM"
    property int scrollOff: 2

    signal historyActivated()
    signal pinnedActivated()
    signal historyClicked(int index)
    signal pinnedClicked(int index)
    signal historyHovered(int index)   // index or -1 to clear
    signal pinnedHovered(int index)

    // Scroll the list to keep the selected index with scrollOff entries above/below
    function scrollToListView(listView, index) {
        if (!listView || index < 0 || index >= listView.count) return
        var dh = 64
        var total = listView.count * dh
        var view = listView.height
        var desiredTop = index * dh - scrollOff * dh
        var minTop = 0
        var maxTop = Math.max(0, total - view)
        desiredTop = Math.max(minTop, Math.min(desiredTop, maxTop))
        if (total < view) desiredTop = 0
        listView.contentY = desiredTop
    }

    onSelectedIndexChanged: {
        // Defer to let currentIndex update
        Qt.callLater(function() {
            if (currentPage === 0)
                scrollToListView(historyList, selectedIndex)
            else
                scrollToListView(pinnedList, selectedIndex)
        })
    }

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
            highlightRangeMode: ListView.NoHighlightRange
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 0
            boundsBehavior: Flickable.StopAtBounds

            delegate: EntryDelegate {
                width: historyList.width; height: 64
                entry: root.historyModel[modelData]
                isCurrent: index === historyList.currentIndex
                isHovered: index === root.hoveredIndex
                highlightColor: root.selColor
                hoverColor: root.hoverColor
                textColor: root.fgColor
                selectedTextColor: root.bgColor
                commentColor: root.commentColor
                fontFamily: root.fontFamily
                onClicked: function(idx) { root.historyClicked(index) }
                onActivated: root.historyActivated()
                onHovered: function(idx) {
                    root.hoveredIndex = index
                    root.historyHovered(index)
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onExited: {
                    root.hoveredIndex = -1
                    root.historyHovered(-1)
                }
            }

            highlight: Rectangle { color: root.selColor; radius: 4 }
        }

        ListView {
            id: pinnedList
            clip: true
            width: root.width
            height: root.height
            model: root.pinnedFiltered
            currentIndex: root.selectedIndex
            highlightRangeMode: ListView.NoHighlightRange
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 0
            boundsBehavior: Flickable.StopAtBounds

            delegate: EntryDelegate {
                width: pinnedList.width; height: 64
                entry: root.pinnedModel[modelData]
                isCurrent: index === pinnedList.currentIndex
                isHovered: index === root.hoveredIndex
                highlightColor: root.selColor
                hoverColor: root.hoverColor
                textColor: root.fgColor
                selectedTextColor: root.bgColor
                commentColor: root.commentColor
                fontFamily: root.fontFamily
                onClicked: function(idx) { root.pinnedClicked(index) }
                onActivated: root.pinnedActivated()
                onHovered: function(idx) {
                    root.hoveredIndex = index
                    root.pinnedHovered(index)
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onExited: {
                    root.hoveredIndex = -1
                    root.pinnedHovered(-1)
                }
            }

            highlight: Rectangle { color: root.selColor; radius: 4 }
        }
    }
}
