import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    Theme { id: theme }
    ClipboardService { id: service }

    // --- State ---
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
    property bool mouseSelection: false
    property int cursorX: 0
    property int cursorY: 0

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string historyPath: homeDir + "/.cache/clipboard-manager/history.json"

    // --- Logic ---
    function updateFilters() {
        var lower = filterText.toLowerCase()
        var hist = [], pin = []
        for (var i = 0; i < historyModel.length; i++) {
            var entry = historyModel[i]
            var display = entry.type === "image" ? "Image" : (entry.content || "")
            if (display.toLowerCase().indexOf(lower) !== -1) hist.push(i)
        }
        historyFiltered = hist
        for (var j = 0; j < pinnedModel.length; j++) {
            if (pinnedModel[j].text.toLowerCase().indexOf(lower) !== -1) pin.push(j)
        }
        pinnedFiltered = pin

        var maxIndex = (currentPage === 0 ? historyFiltered.length : pinnedFiltered.length) - 1
        if (selectedIndex > maxIndex) selectedIndex = Math.max(0, maxIndex)
    }

    onFilterTextChanged: updateFilters()
    onHistoryModelChanged: updateFilters()
    onCurrentPageChanged: { filterText = ""; selectedIndex = 0 }
    onSelectedIndexChanged: { mouseSelection = false }

    function activateHistoryItem() {
        if (selectedIndex < historyFiltered.length) {
            service.callSetSelection(historyFiltered[selectedIndex], function() { Qt.quit() })
        }
    }

    function activatePinnedItem() {
        if (selectedIndex < pinnedFiltered.length) {
            var entry = pinnedModel[pinnedFiltered[selectedIndex]]
            if (entry.text === "💌 e-mail") {
                service.callIgnore(function() { service.readMail(Quickshell.env("XDG_RUNTIME_DIR") + "/mail") })
            } else {
                service.callIgnore(function() { service.copy(entry.text, function() { Qt.quit() }) })
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

    // --- Service Connections ---
    Connections {
        target: service
        function onHistoryLoaded(rawJson) {
            try {
                var doc = JSON.parse(rawJson)
                var entries = doc.entries || []
                entries.sort(function(a, b) { return new Date(b.timestamp || 0).getTime() - new Date(a.timestamp || 0).getTime() })
                root.historyModel = entries
                updateFilters()
            } catch (e) { root.historyModel = []; updateFilters() }
        }
        function onMailLoaded(content) {
            if (content.length > 0) service.copy(content, function() { Qt.quit() })
            else Qt.quit()
        }
        function onCursorPosReady(x, y) {
            cursorX = x; cursorY = y
            panel.visible = true
            focusTimer.start()
        }
    }

    // --- UI Composition ---
    PanelWindow {
        id: panel
        screen: root.screenForCursor()
        visible: false
        color: "transparent"
        anchors.fill: parent
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "clipboard-manager"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        MouseArea { anchors.fill: parent; onClicked: Qt.quit() }

        Rectangle {
            id: popupContent
            width: 400; height: 500
            x: Math.max(0, Math.min(cursorX - panel.screen.x - width / 2, panel.screen.width - width))
            y: Math.max(0, Math.min(cursorY - panel.screen.y - height / 4, panel.screen.height - height))
            color: theme.bgColor; radius: 8
            border.color: theme.commentColor; border.width: 1

            MouseArea { anchors.fill: parent; onClicked: {} }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 4

                FilterBar {
                    id: filterBar
                    text: root.filterText
                    onTextChanged: root.filterText = text
                    currentPage: root.currentPage
                    fgColor: theme.fgColor; fontFamily: theme.fontFamily
                    
                    onEscapePressed: Qt.quit()
                    onPageToggled: root.currentPage = root.currentPage === 0 ? 1 : 0
                    onUpPressed: if (root.selectedIndex > 0) root.selectedIndex--
                    onDownPressed: {
                        var maxIndex = (root.currentPage === 0 ? root.historyFiltered.length : root.pinnedFiltered.length) - 1
                        if (root.selectedIndex < maxIndex) root.selectedIndex++
                    }
                    onLeftPressed: if (root.currentPage === 0) root.currentPage = 1
                    onRightPressed: if (root.currentPage === 1) root.currentPage = 0
                    onReturnPressed: root.currentPage === 0 ? root.activateHistoryItem() : root.activatePinnedItem()
                }

                PagesView {
                    currentPage: root.currentPage
                    historyModel: root.historyModel; historyFiltered: root.historyFiltered
                    pinnedModel: root.pinnedModel; pinnedFiltered: root.pinnedFiltered
                    selectedIndex: root.selectedIndex
                    bgColor: theme.bgColor; selColor: theme.selColor
                    fgColor: theme.fgColor; commentColor: theme.commentColor
                    fontFamily: theme.fontFamily

                    onHistoryClicked: function(index) { root.mouseSelection = true; root.selectedIndex = index }
                    onPinnedClicked: function(index) { root.mouseSelection = true; root.selectedIndex = index }
                    onHistoryHovered: function(index) { root.mouseSelection = true; root.selectedIndex = index }
                    onPinnedHovered: function(index) { root.mouseSelection = true; root.selectedIndex = index }
                    onHistoryActivated: root.activateHistoryItem()
                    onPinnedActivated: root.activatePinnedItem()
                }
            }
        }
    }

    Timer {
        id: focusTimer
        interval: 50; repeat: false
        onTriggered: filterBar.forceFocus()
    }

    Component.onCompleted: {
        service.readHistory(historyPath)
        service.getCursorPos()
    }
}
