import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Scope {
    id: root

    // ----- Font -----
    property string fontFamily: "Iosevka NFM"

    // ----- Colors (fallback) -----
    property color bgColor: "#1a1a2e"
    property color selColor: "#008080"
    property color fgColor: "#f0f0f0"
    property color commentColor: "#4a4a4a"

    // ----- Stylix support -----
    readonly property string stylixPath: Quickshell.env("HOME") + "/.config/stylix/palette.json"

    FileView {
        id: stylixFile
        path: root.stylixPath
        onTextChanged: {
            var raw = text().trim()
            if (raw.length === 0) {
                console.log("Stylix palette file empty, keeping fallback colors")
                return
            }
            try {
                var palette = JSON.parse(raw)
                var colors = palette.palette || palette

                function toColor(hex) {
                    if (!hex) return null
                    hex = hex.toString().trim()
                    if (hex.charAt(0) !== "#") hex = "#" + hex
                    return hex
                }

                var c00 = toColor(colors.base00)
                var c03 = toColor(colors.base03)
                var c05 = toColor(colors.base05)
                var c0e = toColor(colors.base0E) // accent

                if (c00) root.bgColor = c00
                if (c03) root.commentColor = c03
                if (c05) root.fgColor = c05
                if (c0e) root.selColor = c0e

                console.log("Stylix colors loaded:", c00, c0e, c03, c05)
            } catch (e) {
                console.warn("Failed to parse stylix palette:", e)
            }
        }
    }

    // ----- History data -----
    property var historyModel: []
    property var pinnedModel: [
        { type: "pinned", text: formatLocalDateTime(new Date()) },
        { type: "pinned", text: formatLocalDateTime(new Date()).slice(0, 10) },
        { type: "pinned", text: "💌 e-mail" }
    ]

    // ----- Filtering -----
    property string filterText: ""
    property var historyFiltered: []
    property var pinnedFiltered: []
    property int currentPage: 0   // 0 = history, 1 = pinned
    property int selectedIndex: 0

    function updateFilters() {
        var lower = filterText.toLowerCase()
        // History filter
        var hist = []
        for (var i = 0; i < historyModel.length; i++) {
            var entry = historyModel[i]
            var display = entry.type === "image" ? "Image" : (entry.content || "")
            if (display.toLowerCase().indexOf(lower) !== -1)
                hist.push(i)
        }
        historyFiltered = hist

        // Pinned filter
        var pin = []
        for (var j = 0; j < pinnedModel.length; j++) {
            var p = pinnedModel[j]
            if (p.text.toLowerCase().indexOf(lower) !== -1)
                pin.push(j)
        }
        pinnedFiltered = pin

        // Clamp selected index to visible list length
        var maxIndex = (currentPage === 0 ? historyFiltered.length : pinnedFiltered.length) - 1
        if (selectedIndex > maxIndex) selectedIndex = Math.max(0, maxIndex)

        // Update list view position
        var list = currentPage === 0 ? historyList : pinnedList
        if (list.count > 0) {
            list.currentIndex = selectedIndex
            list.positionViewAtIndex(selectedIndex, ListView.Beginning)
        }
    }

    onFilterTextChanged: updateFilters()
    onHistoryModelChanged: updateFilters()
    onCurrentPageChanged: {
        filterField.text = ""
        selectedIndex = 0
        var list = currentPage === 0 ? historyList : pinnedList
        if (list.count > 0) {
            list.currentIndex = 0
            list.positionViewAtIndex(0, ListView.Beginning)
        }
    }
    onSelectedIndexChanged: {
        var list = currentPage === 0 ? historyList : pinnedList
        if (list.count > 0 && selectedIndex < list.count) {
            list.currentIndex = selectedIndex
            list.positionViewAtIndex(selectedIndex, ListView.Beginning)
        }
    }

    // ----- Cursor position -----
    property int cursorX: 0
    property int cursorY: 0

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string historyPath: homeDir + "/.cache/clipboard-manager/history.json"

    Process {
        id: historyReader
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = this.text.trim()
                if (raw.length > 0) {
                    root.tryParseRaw(raw)
                } else {
                    console.warn("File empty – no entries yet")
                    root.historyModel = []
                    updateFilters()
                }
            }
        }
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                console.warn("Failed to read history file, exit:", exitCode)
                root.historyModel = []
                updateFilters()
            }
        }
    }

    function readHistory() {
        historyReader.command = ["cat", historyPath]
        historyReader.running = true
    }

    function tryParseRaw(raw) {
        try {
            var doc = JSON.parse(raw)
            var entries = doc.entries || []
            entries.sort(function(a, b) {
                var ta = new Date(a.timestamp || 0).getTime()
                var tb = new Date(b.timestamp || 0).getTime()
                return tb - ta
            })
            root.historyModel = entries
            updateFilters()
        } catch (e) {
            console.warn("JSON parse error:", e)
            root.historyModel = []
            updateFilters()
        }
    }

    // ----- D-Bus call for SetSelection -----

    Process {
        id: setSelectionProc
        running: false
        property var callback: null

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                console.warn("SetSelection dbus-send failed, exit:", exitCode)
            }
            if (callback) {
                var cb = callback
                callback = null
                cb()
            } else {
                // If no callback, just quit
                Qt.quit()
            }
        }
    }

    function callSetSelection(historyIndex, cb) {
        setSelectionProc.callback = cb
        setSelectionProc.command = [
            "dbus-send",
            "--session",
            "--type=method_call",
            "--dest=org.clipboard.Manager",
            "/",
            "org.clipboard.Manager.SetSelection",
            "int32:" + historyIndex
        ]
        setSelectionProc.running = true
    }

    function formatLocalDateTime(date) {
        var offset = -date.getTimezoneOffset();
        var offsetHours = Math.floor(Math.abs(offset) / 60);
        var offsetMinutes = Math.abs(offset) % 60;
        var offsetStr = (offset >= 0 ? '+' : '-') +
                        String(offsetHours).padStart(2, '0') + ':' +
                        String(offsetMinutes).padStart(2, '0');
        return date.getFullYear() + '-' +
               String(date.getMonth() + 1).padStart(2, '0') + '-' +
               String(date.getDate()).padStart(2, '0') + 'T' +
               String(date.getHours()).padStart(2, '0') + ':' +
               String(date.getMinutes()).padStart(2, '0') + ':' +
               String(date.getSeconds()).padStart(2, '0') + offsetStr;
    }

    // ----- Activation helpers (used by Return and click) -----
    function activateHistoryItem() {
        if (root.selectedIndex < root.historyFiltered.length) {
            var histIndex = root.historyFiltered[root.selectedIndex]
            root.callSetSelection(histIndex, function() {
                Qt.quit()
            })
        }
    }

    function activatePinnedItem() {
        if (root.selectedIndex < root.pinnedFiltered.length) {
            var pinIndex = root.pinnedFiltered[root.selectedIndex]
            var entry = root.pinnedModel[pinIndex]
            if (entry.text === "💌 e-mail") {
                ignoreProc.callIgnore(function() {
                    root.pasteMail()
                })
            } else {
                ignoreProc.callIgnore(function() {
                    wlCopyProc.copy(entry.text)
                })
            }
        }
    }

    // ----- D-Bus call for IgnoreNext (to prevent pinned entries from being logged) -----
    Process {
        id: ignoreProc
        running: false
        property var callback: null

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                console.warn("IgnoreNext dbus-send failed, exit:", exitCode)
            }
            if (callback) {
                var cb = callback
                callback = null
                cb()
            }
        }

        function callIgnore(cb) {
            callback = cb
            command = [
                "dbus-send",
                "--session",
                "--type=method_call",
                "--dest=org.clipboard.Manager",
                "/",
                "org.clipboard.Manager.IgnoreNext"
            ]
            running = true
        }
    }

    // ----- Direct clipboard set via wl-copy (for pinned entries) -----
    Process {
        id: wlCopyProc
        running: false
        property string textToCopy: ""

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                console.warn("wl-copy failed, exit:", exitCode)
            }
            Qt.quit()
        }

        // Use printf with a shell command to safely pass arbitrary text
        function copy(text) {
            textToCopy = text
            command = ["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", text]
            running = true
        }
    }

    // ----- Read e‑mail file (uses wl-copy) -----
    function pasteMail() {
        // This is called after IgnoreNext is already set
        var mailPath = Quickshell.env("XDG_RUNTIME_DIR") + "/mail"
        var proc = mailReader
        proc.command = ["cat", mailPath]
        proc.running = true
    }

    Process {
        id: mailReader
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var content = this.text.trim()
                if (content.length > 0) {
                    wlCopyProc.copy(content)
                    console.log("Mail copied to clipboard")
                } else {
                    console.warn("Mail file empty or not found")
                    Qt.quit()
                }
            }
        }
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                console.warn("Failed to read mail file, exit:", exitCode)
                Qt.quit()
            }
        }
    }

    // ----- Cursor position via hyprctl -----
    Process {
        id: cursorProc
        command: ["hyprctl", "cursorpos", "-j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var pos = JSON.parse(this.text)
                    root.cursorX = pos.x
                    root.cursorY = pos.y
                } catch (e) {
                    console.warn("Failed to parse cursor position:", e)
            }
                panel.visible = true
        }
        }
    }

    function show() {
        readHistory()
        cursorProc.running = true
    }

    Component.onCompleted: {
        console.log("History path:", historyPath)
        stylixFile.path = root.stylixPath
        show()
    }

    function screenForCursor() {
        for (var i = 0; i < Quickshell.screens.length; i++) {
            var s = Quickshell.screens[i]
            if (root.cursorX >= s.x && root.cursorX < s.x + s.width &&
                root.cursorY >= s.y && root.cursorY < s.y + s.height) {
                return s
            }
        }
        return Quickshell.screens[0]
    }

    PanelWindow {
        id: panel
        screen: root.screenForCursor()
        visible: false
        color: "transparent"

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "clipboard-manager"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }

        Rectangle {
            id: popupContent
            width: 400
            height: 500
            x: Math.max(0, Math.min(root.cursorX - panel.screen.x - width / 2, panel.screen.width - width))
            y: Math.max(0, Math.min(root.cursorY - panel.screen.y - height / 4, panel.screen.height - height))
            color: root.bgColor
            radius: 8
            border.color: root.commentColor
            border.width: 1

            MouseArea {
                anchors.fill: parent
                onClicked: {}  // block clicks from closing
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                    TextField {
                        id: filterField
                        Layout.fillWidth: true
                    Layout.preferredHeight: 30
                        placeholderText: "Filter..."
                        color: root.fgColor
                        font.family: root.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                        cursorDelegate: Item { }
                        background: Rectangle {
                            color: "transparent"
                            border.color: "transparent"
                            border.width: 0
                        }
                        text: root.filterText
                        onTextChanged: root.filterText = text

                        Keys.onEscapePressed: Qt.quit()

                        Keys.onUpPressed: function(event) {
                            if (root.selectedIndex > 0) {
                                root.selectedIndex--
                            }
                            event.accepted = true
                        }

                        Keys.onDownPressed: function(event) {
                            var maxIndex = (root.currentPage === 0 ? root.historyFiltered.length : root.pinnedFiltered.length) - 1
                            if (root.selectedIndex < maxIndex)
                                root.selectedIndex++
                            event.accepted = true
                        }

                        Keys.onLeftPressed: function(event) {
                            if (root.currentPage === 0) {
                                root.currentPage = 1
                                event.accepted = true
                            }
                        }

                        Keys.onRightPressed: function(event) {
                            if (root.currentPage === 1) {
                                root.currentPage = 0
                                event.accepted = true
                            }
                        }

                        Keys.onReturnPressed: function(event) {
                            if (root.currentPage === 0) {
                                root.activateHistoryItem()
                            } else {
                                root.activatePinnedItem()
                            }
                            event.accepted = true
                        }
                    }

                // Container that clips and holds the sliding pages
                Item {
                    id: pagesContainer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Row {
                        id: pagesRow
                        width: pagesContainer.width * 2
                        height: pagesContainer.height

                        Behavior on x {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                        }

                        x: root.currentPage === 0 ? 0 : -pagesContainer.width

                        // History list
                        ListView {
                            id: historyList
                            clip: true
                            width: pagesContainer.width
                            height: pagesContainer.height
                            model: root.historyFiltered
                            currentIndex: root.selectedIndex
                            delegate: EntryDelegate {
                                width: historyList.width
                                height: 64
                                entry: root.historyModel[modelData]
                                isCurrent: index === historyList.currentIndex
                                highlightColor: root.selColor
                                textColor: root.fgColor
                                selectedTextColor: root.bgColor
                                commentColor: root.commentColor
                                fontFamily: root.fontFamily
                                onClicked: root.selectedIndex = index
                                onActivated: root.activateHistoryItem()
                            }
                            highlight: Rectangle { color: root.selColor; radius: 4 }
                            highlightFollowsCurrentItem: true
                            highlightMoveDuration: 100
                        }

                        // Pinned list
                        ListView {
                            id: pinnedList
                            clip: true
                            width: pagesContainer.width
                            height: pagesContainer.height
                            model: root.pinnedFiltered
                            currentIndex: root.selectedIndex
                            delegate: EntryDelegate {
                                width: pinnedList.width
                                height: 64
                                entry: root.pinnedModel[modelData]
                                isCurrent: index === pinnedList.currentIndex
                                highlightColor: root.selColor
                                textColor: root.fgColor
                                selectedTextColor: root.bgColor
                                commentColor: root.commentColor
                                fontFamily: root.fontFamily
                                onClicked: root.selectedIndex = index
                                onActivated: root.activatePinnedItem()
                            }
                            highlight: Rectangle { color: root.selColor; radius: 4 }
                            highlightFollowsCurrentItem: true
                            highlightMoveDuration: 100
                        }
                    }
                }
            }
        }

        Timer {
            id: focusTimer
            interval: 50
            running: panel.visible
            repeat: false
            onTriggered: filterField.forceActiveFocus()
        }
    }
}
