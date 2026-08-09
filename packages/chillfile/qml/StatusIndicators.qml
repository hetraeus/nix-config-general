import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

RowLayout {
    id: root
    spacing: 8

    // ----- Backup indicator (🤕) -----
    Label {
        id: backupLabel
        text: "🤕"
        font.pixelSize: 18
        visible: false
        ToolTip {
            text: "Needs backup"
            visible: parent.hovered
        }
    }

    // ----- Session indicator (🥂 / 💔) -----
    Label {
        id: sessionLabel
        text: "🥂"
        font.pixelSize: 18
        ToolTip {
            text: sessionLabel.text === "🥂" ? "Session active" : "Session broken"
            visible: parent.hovered
        }
    }

    // ----- SysRq indicator (🪄 / 🛑) -----
    Label {
        id: sysrqLabel
        text: "🪄"
        font.pixelSize: 18
        ToolTip {
            text: sysrqLabel.text === "🪄" ? "c+m+fn+prtsc -fn" : "no sysrq"
            visible: parent.hovered
        }
    }

    // ----- Performance preset indicator -----
    Label {
        id: perfLabel
        text: "⚖️"
        font.pixelSize: 18
        property string tooltipText: ""
        ToolTip {
            text: "Performance: " + perfLabel.tooltipText
            visible: parent.hovered
        }
    }

    // ---------------------------------------------------------------------
    // Processes & timers
    // ---------------------------------------------------------------------

    // Fast updates: performance only (every 5 s)
    Timer {
        id: fastTimer
        interval: 5000
        running: true
        repeat: true
        onTriggered: updatePerf()
    }

    // Slow updates: backup & sysrq (every 20 h)
    Timer {
        id: slowTimer
        interval: 20 * 60 * 60 * 1000  // 20 hours
        running: true
        repeat: true
        onTriggered: {
            updateBackup();
            updateSysrq();
        }
    }

    // ---------------------------------------------------------------------
    // Update functions
    // ---------------------------------------------------------------------

    function updateBackup() {
        var home = Quickshell.env("HOME") || "";
        if (!home) return;
        var file = home + "/.cache/shell/due_supdate";
        readBackupProc.command = ["cat", file];
        readBackupProc.running = true;
    }

    Process {
        id: readBackupProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var ts = parseInt(text.trim());
                if (!isNaN(ts)) {
                    var now = Math.floor(Date.now() / 1000);
                    backupLabel.visible = (now > ts);
                } else {
                    backupLabel.visible = false;
                }
            }
        }
        onExited: {
            if (exitCode !== 0) backupLabel.visible = false;
        }
    }

    function updateSession() {
        var session = Quickshell.env("WAYLAND_SESSION") || "";
        if (!session) { sessionLabel.text = "💔"; return; }
        sessionProc.command = ["loginctl", "show-session", session, "--property=Active", "--value"];
        sessionProc.running = true;
    }

    Process {
        id: sessionProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var active = text.trim();
                sessionLabel.text = (active === "yes") ? "🥂" : "💔";
            }
        }
        onExited: {
            if (exitCode !== 0) sessionLabel.text = "💔";
        }
    }

    function updateSysrq() {
        sysrqProc.command = ["cat", "/proc/sys/kernel/sysrq"];
        sysrqProc.running = true;
    }

    Process {
        id: sysrqProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var val = text.trim();
                sysrqLabel.text = (val === "1") ? "🪄" : "🛑";
            }
        }
        onExited: {
            if (exitCode !== 0) sysrqLabel.text = "🛑";
        }
    }

    function updatePerf() {
        perfProc.command = ["tuned-adm", "active"];
        perfProc.running = true;
    }

    Process {
        id: perfProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var out = text.trim();
                var match = out.match(/Current active profile:\s*(.+)/);
                var profile = match ? match[1].toLowerCase() : "unknown";
                var icon = "❓";
                var tip = profile;
                switch (profile) {
                    case "balanced": icon = "⚖️"; break;
                    case "powersave": icon = "🌿"; break;
                    case "performance": icon = "🚀"; break;
                    case "desktop": icon = "🖥️"; break;
                    case "throughput-performance": icon = "⚡"; break;
                    default: icon = "⚙️"; break;
                }
                perfLabel.text = icon;
                perfLabel.tooltipText = profile.charAt(0).toUpperCase() + profile.slice(1);
            }
        }
        onExited: {
            if (exitCode !== 0) {
                perfLabel.text = "❓";
                perfLabel.tooltipText = "unknown";
            }
        }
    }

    // ---------------------------------------------------------------------
    // Initial updates
    // ---------------------------------------------------------------------
    Component.onCompleted: {
        updateSession();
        updateBackup();
        updateSysrq();
        updatePerf();
    }
}
