import QtQuick 2.15
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // --- History Reader ---
    Process {
        id: historyReader
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.historyLoaded(text.trim())
        }
    }
    signal historyLoaded(string rawJson)
    function readHistory(path) {
        historyReader.command = ["cat", path]
        historyReader.running = true
    }

    // --- D-Bus SetSelection ---
    Process {
        id: setSelectionProc
        running: false
        property var callback: null
        onExited: function(exitCode) { if (callback) { var cb = callback; callback = null; cb() } }
    }
    function callSetSelection(historyIndex, cb) {
        setSelectionProc.callback = cb
        setSelectionProc.command = ["dbus-send", "--session", "--type=method_call", "--dest=org.clipboard.Manager", "/", "org.clipboard.Manager.SetSelection", "int32:" + historyIndex]
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
        ignoreProc.command = ["dbus-send", "--session", "--type=method_call", "--dest=org.clipboard.Manager", "/", "org.clipboard.Manager.IgnoreNext"]
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
        wlCopyProc.command = ["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", text]
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

    // --- Cursor Position ---
    Process {
        id: cursorProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var pos = JSON.parse(text)
                    root.cursorPosReady(pos.x, pos.y)
                } catch (e) { root.cursorPosReady(0, 0) }
            }
        }
    }
    signal cursorPosReady(int x, int y)
    function getCursorPos() {
        cursorProc.command = ["hyprctl", "cursorpos", "-j"]
        cursorProc.running = true
    }
}

