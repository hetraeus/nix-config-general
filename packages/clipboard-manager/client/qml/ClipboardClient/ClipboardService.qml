import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string historyPath: homeDir + "/.cache/clipboard-manager/history.json"

    signal historyLoaded(string rawJson)
    signal mailLoaded(string content)
    signal showRequested(int x, int y)

    // --- Listen for D-Bus signals from the server ---
    //
    // Two signals matter here:
    //   ShowRequested(x, y) — emitted by the hotkey path; two int32 args.
    //   HistoryChanged()    — emitted whenever the server mutates history.json
    //                         (add / bump / delete). No args.
    //
    // dbus-monitor is started with one match rule per signal. Its stdout for a
    // matched signal looks like:
    //
    //   signal time=... sender=... -> ... interface=org.clipboard.Manager; member=ShowRequested
    //      int32 1234
    //      int32 5678
    //   signal time=... sender=... -> ... interface=org.clipboard.Manager; member=HistoryChanged
    //
    // The parser tracks which signal it's currently inside via pendingMember,
    // and for ShowRequested accumulates the two int32 coordinates across lines.
    property int pendingX: 0
    property bool hasX: false
    property string pendingMember: ""

    Process {
        id: dbusMonitor
        running: true
        command: [
            "dbus-monitor", "--session",
            "type='signal',interface='org.clipboard.Manager',member='ShowRequested'",
            "type='signal',interface='org.clipboard.Manager',member='HistoryChanged'"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                // --- signal header lines ---
                if (line.indexOf("member=ShowRequested") !== -1) {
                    root.pendingMember = "ShowRequested"
                    root.hasX = false
                    root.pendingX = 0
                    return
                }
                if (line.indexOf("member=HistoryChanged") !== -1) {
                    root.pendingMember = ""
                    // The server rewrites history.json via remove+rename, so the
                    // file's inode changes on every save and FileView's inotify
                    // watch silently goes stale. Force a re-read whenever the
                    // server tells us the file changed.
                    historyFile.reload()
                    return
                }

                // --- ShowRequested body: two int32 lines ---
                if (root.pendingMember === "ShowRequested") {
                    var match = line.match(/int32\s+(-?\d+)/)
                    if (!match) return
                    var value = parseInt(match[1], 10)
                    if (isNaN(value)) return

                    if (!root.hasX) {
                        root.pendingX = value
                        root.hasX = true
                    } else {
                        root.showRequested(root.pendingX, value)
                        root.hasX = false
                        root.pendingX = 0
                        root.pendingMember = ""
                    }
                }
            }
        }
    }

    // --- Read history file ---
    FileView {
        id: historyFile
        path: root.historyPath
        watchChanges: true
        onTextChanged: {
            root.historyLoaded(text().trim())
        }
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
}
