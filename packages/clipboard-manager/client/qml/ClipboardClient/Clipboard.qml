import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    Theme { id: theme }
    ClipboardService { id: service }

    // --- State (unchanged) ---
    property var historyModel: []
    property var pinnedModel: [
        { type: "pinned", text: formatLocalDateTime(new Date()) },
        { type: "pinned", text: formatLocalDateTime(new Date()).slice(0, 10) },
        { type: "pinned", text: "💌 e-mail" }
    ]
    property string filterText: ""
    property var historyFiltered: []
    property var pinnedFiltered: []
    property int currentPage: 0
    property int selectedIndex: 0
    property int hoveredIndex: -1
    property int cursorX: 0
    property int cursorY: 0
    property bool deleteDialogVisible: false
    property int deleteTargetIndex: -1
    property bool panelVisible: false

    readonly property int historyLimit: 100

    // --- Show / Hide API ---
    function show() {
        filterText = ""
        currentPage = 0
        selectedIndex = 0
        hoveredIndex = -1
        deleteDialogVisible = false
        deleteTargetIndex = -1
        panelVisible = true
        maybeFocusFilterBar()
    }

    function hide() {
        panelVisible = false
        deleteDialogVisible = false
    }

    // --- Logic (unchanged) ---
    function updateFilters() {
        var lower = filterText.toLowerCase()
        var hist = [], pin = []
        for (var i = 0; i < historyModel.length; i++) {
            if (historyModel[i]._searchKey.indexOf(lower) !== -1) hist.push(i)
        }
        historyFiltered = hist
        for (var j = 0; j < pinnedModel.length; j++) {
            if (pinnedModel[j].text.toLowerCase().indexOf(lower) !== -1) pin.push(j)
        }
        pinnedFiltered = pin

        var maxIndex = (currentPage === 0 ? historyFiltered.length : pinnedFiltered.length) - 1
        if (selectedIndex > maxIndex) selectedIndex = Math.max(0, maxIndex)
    }

    onFilterTextChanged: {
        updateFilters()
        var fb = contentLoader.item ? contentLoader.item.filterBar : null
        if (fb && fb.text !== filterText) fb.text = filterText
    }
    onHistoryModelChanged: updateFilters()
    onCurrentPageChanged: { filterText = ""; selectedIndex = 0 }

    function activateHistoryItem() {
        if (selectedIndex < historyFiltered.length) {
            var idx = historyFiltered[selectedIndex]
            service.callSetSelection(idx, function() {
                root.selectedIndex = 0
                root.hoveredIndex = -1
                root.hide()
            })
        }
    }

    function requestDelete() {
        if (currentPage !== 0) return
        if (selectedIndex >= historyFiltered.length) return
        deleteTargetIndex = historyFiltered[selectedIndex]
        deleteDialogVisible = true
    }

    function cancelDelete() {
        deleteDialogVisible = false
        deleteTargetIndex = -1
    }

    function confirmDelete() {
        if (deleteTargetIndex < 0) { cancelDelete(); return }
        var idx = deleteTargetIndex
        deleteTargetIndex = -1
        deleteDialogVisible = false
        service.callDeleteEntry(idx, function() {})
    }

    function activatePinnedItem() {
        if (selectedIndex < pinnedFiltered.length) {
            var entry = pinnedModel[pinnedFiltered[selectedIndex]]
            if (entry.text === "💌 e-mail") {
                service.callIgnore(function() {
                    service.readMail(Quickshell.env("XDG_RUNTIME_DIR") + "/mail")
                })
            } else {
                service.callIgnore(function() {
                    service.copy(entry.text, function() { root.hide() })
                })
            }
        }
    }

    function formatLocalDateTime(date) {
        var offset = -date.getTimezoneOffset();
        var offsetHours = Math.floor(Math.abs(offset) / 60);
        var offsetMinutes = Math.abs(offset) % 60;
        var offsetStr = (offset >= 0 ? '+' : '-') + String(offsetHours).padStart(2, '0') + ':' + String(offsetMinutes).padStart(2, '0');
        return date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0') + '-' + String(date.getDate()).padStart(2, '0') + 'T' + String(date.getHours()).padStart(2, '0') + ':' + String(date.getMinutes()).padStart(2, '0') + ':' + String(date.getSeconds()).padStart(2, '0') + offsetStr;
    }

    function screenForCursor() {
        for (var i = 0; i < Quickshell.screens.length; i++) {
            var s = Quickshell.screens[i]
            if (cursorX >= s.x && cursorX < s.x + s.width && cursorY >= s.y && cursorY < s.y + s.height) return s
        }
        return Quickshell.screens[0]
    }

    function maybeFocusFilterBar() {
        if (!panelVisible) return
        var item = contentLoader.item
        if (item && item.filterBar) item.filterBar.forceFocus()
    }

    // --- Service Connections ---
    Connections {
        target: service

        function onHistoryLoaded(rawJson) {
            try {
                var doc = JSON.parse(rawJson)
                var entries = (doc.entries || [])
                    .sort(function(a, b) {
                        return new Date(b.timestamp || 0).getTime() - new Date(a.timestamp || 0).getTime()
                    })
                    .slice(0, root.historyLimit)
                for (var i = 0; i < entries.length; i++) {
                    var e = entries[i]
                    e._searchKey = (e.type === "image" ? "image" : (e.content || "")).toLowerCase()
                }
                root.historyModel = entries
            } catch (e) {
                root.historyModel = []
            }
        }

        function onMailLoaded(content) {
            if (content.length > 0) service.copy(content, function() { root.hide() })
            else root.hide()
        }

        // Server pushes show intent + cursor position in one call.
        function onShowRequested(x, y) {
            cursorX = x
            cursorY = y
            root.show()
        }
    }

    // --- UI Composition ---
    PanelWindow {
        id: panel
        screen: root.screenForCursor()
        visible: root.panelVisible
        color: "transparent"

        WlrLayershell.namespace: "clipboard-manager"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.anchors.top: true
        WlrLayershell.anchors.bottom: true
        WlrLayershell.anchors.left: true
        WlrLayershell.anchors.right: true
        WlrLayershell.exclusiveZone: 0

        MouseArea { anchors.fill: parent; onClicked: root.hide() }

        Loader {
            id: contentLoader
            anchors.fill: parent
            active: true
            asynchronous: true
            sourceComponent: popupComponent
            onLoaded: root.maybeFocusFilterBar()
        }
    }

    Component {
        id: popupComponent

        Item {
            id: popupRoot
            property alias filterBar: filterBar
            property alias pagesView: pagesView

            Rectangle {
                id: popupContent
                width: 400
                height: 500
                x: Math.max(0, Math.min(root.cursorX - panel.screen.x - width / 2,
                                         panel.screen.width - width))
                y: Math.max(0, Math.min(root.cursorY - panel.screen.y - height / 4,
                                         panel.screen.height - height))
                color: theme.bgColor
                radius: 8
                border.color: theme.commentColor
                border.width: 1

                MouseArea { anchors.fill: parent; onClicked: {} }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    FilterBar {
                        id: filterBar
                        onTextChanged: root.filterText = text
                        currentPage: root.currentPage
                        fgColor: theme.fgColor
                        fontFamily: theme.fontFamily
                        onEscapePressed: root.hide()
                        onPageToggled: root.currentPage = root.currentPage === 0 ? 1 : 0
                        onUpPressed: { if (root.selectedIndex > 0) root.selectedIndex-- }
                        onDownPressed: {
                            var maxIndex = (root.currentPage === 0
                                ? root.historyFiltered.length
                                : root.pinnedFiltered.length) - 1
                            if (root.selectedIndex < maxIndex) root.selectedIndex++
                        }
                        onLeftPressed:  if (root.currentPage === 0) root.currentPage = 1
                        onRightPressed: if (root.currentPage === 1) root.currentPage = 0
                        onReturnPressed: {
                            root.currentPage === 0
                                ? root.activateHistoryItem()
                                : root.activatePinnedItem()
                        }
                        onDeletePressed: root.requestDelete()
                    }

                    PagesView {
                        id: pagesView
                        currentPage: root.currentPage
                        historyModel: root.historyModel
                        historyFiltered: root.historyFiltered
                        pinnedModel: root.pinnedModel
                        pinnedFiltered: root.pinnedFiltered
                        selectedIndex: root.selectedIndex
                        hoveredIndex: root.hoveredIndex
                        bgColor: theme.bgColor
                        selColor: theme.selColor
                        hoverColor: "#404060"
                        fgColor: theme.fgColor
                        commentColor: theme.commentColor
                        fontFamily: theme.fontFamily
                        scrollOff: 2
                        onHistoryClicked: function(index) {
                            root.selectedIndex = index
                            root.activateHistoryItem()
                        }
                        onPinnedClicked: function(index) {
                            root.selectedIndex = index
                            root.activatePinnedItem()
                        }
                        onHistoryHovered: function(index) { root.hoveredIndex = index }
                        onPinnedHovered:  function(index) { root.hoveredIndex = index }
                        onHistoryActivated: root.activateHistoryItem()
                        onPinnedActivated:  root.activatePinnedItem()
                    }
                }
            }

            FocusScope {
                id: deleteDialog
                anchors.fill: popupContent
                visible: root.deleteDialogVisible
                z: 100

                Rectangle {
                    anchors.fill: parent
                    color: "#aa000000"
                    radius: 8
                    MouseArea { anchors.fill: parent; onClicked: root.cancelDelete() }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 280
                    height: 130
                    color: theme.bgColor
                    border.color: theme.commentColor
                    border.width: 1
                    radius: 8

                    MouseArea { anchors.fill: parent; onClicked: {} }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            text: "Delete this entry from history?"
                            color: theme.fgColor
                            font.family: theme.fontFamily
                            font.pointSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                id: cancelButton
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                color: cancelHover.containsMouse || activeFocus
                                       ? "#404060" : "transparent"
                                border.color: activeFocus ? theme.fgColor : theme.commentColor
                                border.width: activeFocus ? 2 : 1
                                radius: 4
                                focus: true
                                Text {
                                    anchors.centerIn: parent
                                    text: "Cancel"
                                    color: theme.fgColor
                                    font.family: theme.fontFamily
                                }
                                MouseArea {
                                    id: cancelHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.cancelDelete()
                                }
                                Keys.onReturnPressed: root.cancelDelete()
                                Keys.onEnterPressed:  root.cancelDelete()
                            }

                            Rectangle {
                                id: deleteButton
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                color: delHover.containsMouse || activeFocus
                                       ? "#a04040" : "#602020"
                                border.color: activeFocus ? theme.fgColor : theme.commentColor
                                border.width: activeFocus ? 2 : 1
                                radius: 4
                                Text {
                                    anchors.centerIn: parent
                                    text: "Delete"
                                    color: theme.fgColor
                                    font.family: theme.fontFamily
                                }
                                MouseArea {
                                    id: delHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.confirmDelete()
                                }
                                Keys.onReturnPressed: root.confirmDelete()
                                Keys.onEnterPressed:  root.confirmDelete()
                            }
                        }
                    }
                }

                onVisibleChanged: {
                    if (visible) cancelButton.forceActiveFocus()
                    else Qt.callLater(root.maybeFocusFilterBar)
                }

                Keys.onEscapePressed: root.cancelDelete()
                Keys.onTabPressed: function(event) {
                    if (cancelButton.activeFocus) deleteButton.forceActiveFocus()
                    else cancelButton.forceActiveFocus()
                    event.accepted = true
                }
            }
        }
    }
}
