import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

RowLayout {
    id: root
    spacing: 8

    required property var desktop

    // ----- Backup indicator (🤕) -----
    Label {
        id: backupLabel
        text: "🤕"
        font.pixelSize: 18
        visible: false
        property bool hovered: false
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.hovered = true
            onExited: parent.hovered = false
        }
        onHoveredChanged: {
            if (hovered) {
                backupTipTimer.start();
            } else {
                backupTipTimer.stop();
                backupTip.visible = false;
            }
        }
        Timer {
            id: backupTipTimer
            interval: 1500
            onTriggered: backupTip.visible = true
        }
        ToolTip {
            id: backupTip
            text: "Need backups!"
            visible: false
            background: Rectangle {
                color: root.desktop.base01
                border.color: Qt.rgba(root.desktop.base04.r, root.desktop.base04.g, root.desktop.base04.b, 0.3)
                border.width: 1
                radius: 4
            }
            contentItem: Label {
                text: backupTip.text
                color: root.desktop.base04
                font.pixelSize: 13
            }
        }
    }

    // ----- Session indicator (🥂 / 💔) -----
    Label {
        id: sessionLabel
        text: "🥂"
        font.pixelSize: 18
        property bool hovered: false
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.hovered = true
            onExited: parent.hovered = false
        }
        onHoveredChanged: {
            if (hovered) {
                sessionTipTimer.start();
            } else {
                sessionTipTimer.stop();
                sessionTip.visible = false;
            }
        }
        Timer {
            id: sessionTipTimer
            interval: 1500
            onTriggered: sessionTip.visible = true
        }
        ToolTip {
            id: sessionTip
            text: sessionLabel.text === "🥂" ? "Systemd user session active" : "Systemd user session broken"
            visible: false
            background: Rectangle {
                color: root.desktop.base01
                border.color: Qt.rgba(root.desktop.base04.r, root.desktop.base04.g, root.desktop.base04.b, 0.3)
                border.width: 1
                radius: 4
            }
            contentItem: Label {
                text: sessionTip.text
                color: root.desktop.base04
                font.pixelSize: 13
            }
        }
    }

    // ----- SysRq indicator (🪄 / 🛑) -----
    Label {
        id: sysrqLabel
        text: "🪄"
        font.pixelSize: 18
        property bool hovered: false
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.hovered = true
            onExited: parent.hovered = false
        }
        onHoveredChanged: {
            if (hovered) {
                sysrqTipTimer.start();
            } else {
                sysrqTipTimer.stop();
                sysrqTip.visible = false;
            }
        }
        Timer {
            id: sysrqTipTimer
            interval: 1500
            onTriggered: sysrqTip.visible = true
        }
        ToolTip {
            id: sysrqTip
            text: sysrqLabel.text === "🪄" ? "SysRq active (c+m+fn+prtsc -fn)" : "SysRq disabled"
            visible: false
            background: Rectangle {
                color: root.desktop.base01
                border.color: Qt.rgba(root.desktop.base04.r, root.desktop.base04.g, root.desktop.base04.b, 0.3)
                border.width: 1
                radius: 4
            }
            contentItem: Label {
                text: sysrqTip.text
                color: root.desktop.base04
                font.pixelSize: 13
            }
        }
    }

    // ----- Performance preset indicator -----
    Label {
        id: perfLabel
        text: "⚖️"
        font.pixelSize: 18
        property string tooltipText: ""
        property bool hovered: false
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: parent.hovered = true
            onExited: parent.hovered = false
            onClicked: launchPowerProfilesMenu.running = true
        }
        onHoveredChanged: {
            if (hovered) {
                perfTipTimer.start();
            } else {
                perfTipTimer.stop();
                perfTip.visible = false;
            }
        }
        Timer {
            id: perfTipTimer
            interval: 1500
            onTriggered: perfTip.visible = true
        }
        ToolTip {
            id: perfTip
            text: "Power profile: " + perfLabel.tooltipText
            visible: false
            background: Rectangle {
                color: root.desktop.base01
                border.color: Qt.rgba(root.desktop.base04.r, root.desktop.base04.g, root.desktop.base04.b, 0.3)
                border.width: 1
                radius: 4
            }
            contentItem: Label {
                text: perfTip.text
                color: root.desktop.base04
                font.pixelSize: 13
            }
        }

        Process {
            id: launchPowerProfilesMenu
            command: ["fmenu-powerprofiles"]
            running: false
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
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) backupLabel.visible = false;
        }
    }

    // Session detection: quickshell runs as a systemd --user *service*
    // (see package.nix), which is NOT a member of a session-*.scope cgroup.
    // That means "self" resolution (sd_pid_get_session, which walks the
    // caller's own cgroup) has nothing to find and always fails here - this
    // is a different failure mode from the earlier WAYLAND_SESSION issue.
    // Instead, resolve the session by user id: prefer the user's "Display"
    // session (the active graphical one), falling back to the first
    // session listed for the user if Display is empty.
    function updateSession() {
        sessionProc.command = ["sh", "-c",
            "sid=$(loginctl show-user \"$(id -u)\" --property=Display --value 2>/dev/null); " +
            "if [ -z \"$sid\" ]; then sid=$(loginctl show-user \"$(id -u)\" --property=Sessions --value 2>/dev/null | awk '{print $1}'); fi; " +
            "if [ -z \"$sid\" ]; then echo unknown; exit 1; fi; " +
            "loginctl show-session \"$sid\" --property=State --value"
        ];
        sessionProc.running = true;
    }

    Process {
        id: sessionProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var state = text.trim();
                sessionLabel.text = (state === "active" || state === "online") ? "🥂" : "💔";
            }
        }
        onExited: function(exitCode, exitStatus) {
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
        onExited: function(exitCode, exitStatus) {
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
        onExited: function(exitCode, exitStatus) {
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
