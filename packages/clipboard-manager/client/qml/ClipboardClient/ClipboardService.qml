import QtQuick 2.15
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string historyPath: homeDir + "/.cache/clipboard-manager/history.json"
    readonly property string runtimeDir: {
        var r = Quickshell.env("XDG_RUNTIME_DIR")
        return (r && r.length > 0) ? r : "/tmp"
    }
    readonly property string showRequestPath: runtimeDir + "/clipboard-manager/show-request"
    readonly property string lockPath: runtimeDir + "/clipboard-client.lock"

    property int lastSeq: -1

    signal historyLoaded(string rawJson)
    signal mailLoaded(string content)
    signal showRequested(int x, int y)

    // Hold an exclusive flock for the lifetime of this process. The server
    // uses the same lock file to decide whether a client is already alive
    // and needs to be spawned. If we can't get the lock, another client
    // owns it and we exit immediately.
    Process {
        id: lockHolder
        running: true
        command: ["flock", "-n", root.lockPath, "sleep", "infinity"]
        onExited: function(exitCode) {
            if (exitCode !== 0)
                Qt.quit()
        }
    }

    // Watch the show-request file. The server writes "seq epoch_ms x y\n"
    // on every Show() call. We act only on new sequence numbers with a
    // recent timestamp, so a client restart never pops a stale panel.
    FileView {
        id: showRequestFile
        path: root.showRequestPath
        watchChanges: true
        onTextChanged: {
            var raw = text().trim()
            if (raw.length === 0) return
            var parts = raw.split(/\s+/)
            if (parts.length < 4) return
            var seq = parseInt(parts[0])
            var epochMs = parseInt(parts[1])
            var x = parseInt(parts[2])
            var y = parseInt(parts[3])
            if (isNaN(seq) || isNaN(epochMs) || isNaN(x) || isNaN(y)) return
            if (seq <= root.lastSeq) return
            root.lastSeq = seq
            if (Date.now() - epochMs > 5000) return    // stale
            root.showRequested(x, y)
        }
    }

    FileView {
        id: historyFile
        path: root.historyPath
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
