import QtQuick 2.15
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string historyPath: homeDir + "/.cache/clipboard-manager/history.json"

    FileView {
        id: historyFile
        path: root.historyPath
        onTextChanged: {
            root.historyLoaded(text().trim())
        }
    }

    signal historyLoaded(string rawJson)

    // --- D-Bus SetSelection ---
    Process {
        id: setSelectionProc
        running: false
        property var callback: null
        onExited: function(exitCode) { if (callback) { var cb = callback; callback = null; cb() } }
    }
    function callSetSelection(historyIndex, cb) {
        setSelectionProc.callback = cb
        setSelectionProc.command = ["dbus-send", "--session", "--type=method_call",
            "--dest=org.clipboard.Manager", "/",
            "org.clipboard.Manager.SetSelection", "int32:" + historyIndex]
        setSelectionProc.running = true
    }

    // --- D-Bus IgnoreNext ---
    Process {
        id: ignoreProc
        running: false
        property var callback: null
        onExited: function(exitCode) { if (callback) { var cb = callback; callback = null; cb() } }
    }
    function callIgnore(cb) {
        ignoreProc.callback = cb
        ignoreProc.command = ["dbus-send", "--session", "--type=method_call",
            "--dest=org.clipboard.Manager", "/",
            "org.clipboard.Manager.IgnoreNext"]
        ignoreProc.running = true
    }

    // --- wl-copy ---
    Process {
        id: wlCopyProc
        running: false
        property var callback: null
        onExited: function(exitCode) {
            if (callback) { var cb = callback; callback = null; cb() }
            else { Qt.quit() }
        }
    }
    function copy(text, cb) {
        wlCopyProc.callback = cb
        wlCopyProc.command = ["sh", "-c",
            "printf '%s' \"$1\" | wl-copy && printf '%s' \"$1\" | wl-copy --primary",
            "sh", text]
        wlCopyProc.running = true
    }

    // --- Mail Reader ---
    Process {
        id: mailReader
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.mailLoaded(text.trim())
        }
    }
    signal mailLoaded(string content)
    function readMail(path) {
        mailReader.command = ["cat", path]
        mailReader.running = true
    }

    // --- D-Bus DeleteEntry ---
    Process {
        id: deleteEntryProc
        running: false
        property var callback: null
        onExited: function(exitCode) { if (callback) { var cb = callback; callback = null; cb() } }
    }
    function callDeleteEntry(historyIndex, cb) {
        deleteEntryProc.callback = cb
        deleteEntryProc.command = ["dbus-send", "--session", "--type=method_call",
            "--dest=org.clipboard.Manager", "/",
            "org.clipboard.Manager.DeleteEntry", "int32:" + historyIndex]
        deleteEntryProc.running = true
    }

    // --- Cursor Position ---
    signal cursorPosReady(int x, int y)
    function getCursorPos() {
        var x = parseInt(Quickshell.env("CLIPBOARD_X"))
        var y = parseInt(Quickshell.env("CLIPBOARD_Y"))
        if (isNaN(x)) x = 0
        if (isNaN(y)) y = 0
        root.cursorPosReady(x, y)
    }
}
