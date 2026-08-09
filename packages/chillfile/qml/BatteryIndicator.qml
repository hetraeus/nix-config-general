import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

RowLayout {
    id: root
    spacing: 8

    // ----- AC indicator (🔌 when connected) -----
    Label {
        id: acLabel
        text: ""
        font.pixelSize: 18
        ToolTip {
            text: "AC connected"
            visible: parent.hovered && parent.text !== ""
        }
    }

    // ----- Battery percentage + icon (🔋/🔌) -----
    Label {
        id: batteryLabel
        text: "🔋 ?"
        font.pixelSize: 18
        property string tooltipText: ""
        ToolTip {
            text: batteryLabel.tooltipText
            visible: parent.hovered
        }
    }

    // ----- Health (❤️) -----
    Label {
        id: healthLabel
        text: ""
        font.pixelSize: 18
        visible: false
        ToolTip {
            text: "Health: " + healthLabel.text
            visible: parent.hovered
        }
    }

    // ----- Charge limit mode (🔋80 / 🔋100) -----
    Label {
        id: limitLabel
        text: ""
        font.pixelSize: 18
        visible: false
        ToolTip {
            text: "Charge limit: " + limitLabel.text
            visible: parent.hovered
        }
    }

    // ---------------------------------------------------------------------
    // Properties
    // ---------------------------------------------------------------------
    property string batteryPath: ""
    property string acPath: ""

    // ---------------------------------------------------------------------
    // Timers
    // ---------------------------------------------------------------------
    // Fast: AC, battery, limit (every 45 s)
    Timer {
        id: fastTimer
        interval: 45000
        running: true
        repeat: true
        onTriggered: {
            updateAC();
            updateBattery();
            updateLimit();
        }
    }

    // Slow: health (every 20 h)
    Timer {
        id: healthTimer
        interval: 20 * 60 * 60 * 1000
        running: true
        repeat: true
        onTriggered: updateHealth()
    }

    // ---------------------------------------------------------------------
    // Find battery and AC paths (run once)
    // ---------------------------------------------------------------------
    function discoverPaths() {
        discoverProc.command = ["sh", "-c",
            "for d in /sys/class/power_supply/BAT*; do if [ -d \"$d\" ]; then echo \"$d\"; break; fi; done; " +
            "for d in /sys/class/power_supply/AC*; do if [ -d \"$d\" ]; then echo \"$d\"; break; fi; done"
        ];
        discoverProc.running = true;
    }

    Process {
        id: discoverProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                if (lines.length >= 1 && lines[0]) root.batteryPath = lines[0];
                if (lines.length >= 2 && lines[1]) root.acPath = lines[1];
                updateAC();
                updateBattery();
                updateHealth();
                updateLimit();
            }
        }
        onExited: {
            if (!root.batteryPath) {
                batteryLabel.text = "🔋 ?";
                healthLabel.visible = false;
                limitLabel.visible = false;
            }
            if (!root.acPath) acLabel.visible = false;
        }
    }

    // ---------------------------------------------------------------------
    // Update functions
    // ---------------------------------------------------------------------
    function updateAC() {
        if (!root.acPath) return;
        acProc.command = ["cat", root.acPath + "/online"];
        acProc.running = true;
    }

    Process {
        id: acProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var online = parseInt(text.trim());
                acLabel.text = (online === 1) ? "🔌" : "";
            }
        }
    }

    function updateBattery() {
        if (!root.batteryPath) return;
        batProc.command = ["sh", "-c",
            "capacity=$(cat " + root.batteryPath + "/capacity 2>/dev/null || echo 0); " +
            "status=$(cat " + root.batteryPath + "/status 2>/dev/null || echo Unknown); " +
            "echo \"$capacity $status\""
        ];
        batProc.running = true;
    }

    Process {
        id: batProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(/\s+/);
                var cap = parseInt(parts[0]) || 0;
                var status = parts.slice(1).join(" ") || "Unknown";
                var icon = "🔋";
                if (status === "Charging") icon = "🔌";
                else if (status === "Discharging") icon = "🔋";
                else if (status === "Full") icon = "🔋";
                batteryLabel.text = icon + " " + cap + "%";
                var tip = "Battery: " + cap + "% (" + status + ")";
                batteryLabel.tooltipText = tip;
            }
        }
        onExited: {
            if (exitCode !== 0) batteryLabel.text = "🔋 ?";
        }
    }

    function updateHealth() {
        if (!root.batteryPath) return;
        healthProc.command = ["sh", "-c",
            "full=$(cat " + root.batteryPath + "/charge_full 2>/dev/null || echo 0); " +
            "design=$(cat " + root.batteryPath + "/charge_full_design 2>/dev/null || echo 0); " +
            "if [ $design -gt 0 ]; then echo $(( full * 100 / design )); else echo 0; fi"
        ];
        healthProc.running = true;
    }

    Process {
        id: healthProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var health = parseInt(text.trim());
                if (health > 0 && health <= 100) {
                    healthLabel.text = "❤️ " + health + "%";
                    healthLabel.visible = true;
                } else {
                    healthLabel.visible = false;
                }
            }
        }
        onExited: {
            if (exitCode !== 0) healthLabel.visible = false;
        }
    }

    function updateLimit() {
        if (!root.batteryPath) return;
        limitProc.command = ["sh", "-c",
            "if [ -f " + root.batteryPath + "/charge_control_end_threshold ]; then " +
            "  cat " + root.batteryPath + "/charge_control_end_threshold; " +
            "else echo 100; fi"
        ];
        limitProc.running = true;
    }

    Process {
        id: limitProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var limit = parseInt(text.trim()) || 100;
                if (limit >= 0 && limit <= 100) {
                    limitLabel.text = "🔋" + limit + "%";
                    limitLabel.visible = true;
                } else {
                    limitLabel.visible = false;
                }
            }
        }
        onExited: {
            if (exitCode !== 0) limitLabel.visible = false;
        }
    }

    // ---------------------------------------------------------------------
    // Initialisation
    // ---------------------------------------------------------------------
    Component.onCompleted: {
        discoverPaths();
    }
}
