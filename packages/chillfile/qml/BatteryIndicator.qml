import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

RowLayout {
    id: root
    spacing: 8

    required property var desktop

    // ----- AC indicator (🔌 when connected) -----
    Label {
        id: acLabel
        text: ""
        font.pixelSize: 18
        color: "white"
        property bool hovered: false
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.hovered = true
            onExited: parent.hovered = false
        }
        onHoveredChanged: {
            if (hovered && acLabel.text !== "") {
                acTipTimer.start();
            } else {
                acTipTimer.stop();
                acTip.visible = false;
            }
        }
        Timer {
            id: acTipTimer
            interval: 1500
            onTriggered: acTip.visible = true
        }
        ToolTip {
            id: acTip
            text: "Connected to AC"
            visible: false
            background: Rectangle {
                color: root.desktop.base01
                border.color: Qt.rgba(root.desktop.base04.r, root.desktop.base04.g, root.desktop.base04.b, 0.3)
                border.width: 1
                radius: 4
            }
            contentItem: Label {
                text: acTip.text
                color: root.desktop.base04
                font.pixelSize: 13
            }
        }
    }

    // ----- Battery percentage + icon (🔋/🔌) -----
    Label {
        id: batteryLabel
        text: "🔋 ?"
        font.pixelSize: 18
        color: "white"
        property string tooltipText: ""
        property string chargeText: ""
        property bool hovered: false
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.hovered = true
            onExited: parent.hovered = false
        }
        onHoveredChanged: {
            if (hovered) {
                batteryTipTimer.start();
            } else {
                batteryTipTimer.stop();
                batteryTip.visible = false;
            }
        }
        Timer {
            id: batteryTipTimer
            interval: 1500
            onTriggered: batteryTip.visible = true
        }
        ToolTip {
            id: batteryTip
            text: batteryLabel.tooltipText
            visible: false
            background: Rectangle {
                color: root.desktop.base01
                border.color: Qt.rgba(root.desktop.base04.r, root.desktop.base04.g, root.desktop.base04.b, 0.3)
                border.width: 1
                radius: 4
            }
            contentItem: Label {
                text: batteryTip.text
                color: root.desktop.base04
                font.pixelSize: 13
            }
        }
    }

    // ----- Charge limit mode (🧢 80% / 🧢 100%) -----
    Label {
        id: limitLabel
        text: ""
        font.pixelSize: 18
        color: "white"
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
                limitTipTimer.start();
            } else {
                limitTipTimer.stop();
                limitTip.visible = false;
            }
        }
        Timer {
            id: limitTipTimer
            interval: 1500
            onTriggered: limitTip.visible = true
        }
        ToolTip {
            id: limitTip
            text: "Charge limit: " + limitLabel.text
            visible: false
            background: Rectangle {
                color: root.desktop.base01
                border.color: Qt.rgba(root.desktop.base04.r, root.desktop.base04.g, root.desktop.base04.b, 0.3)
                border.width: 1
                radius: 4
            }
            contentItem: Label {
                text: limitTip.text
                color: root.desktop.base04
                font.pixelSize: 13
            }
        }
    }

    // ---------------------------------------------------------------------
    // Properties
    // ---------------------------------------------------------------------
    property string batteryPath: ""
    property string acPath: ""
    // Health isn't shown as its own icon (it doesn't need to live on the bar
    // permanently) - it's folded into the battery tooltip instead, below.
    property string batteryHealthText: ""

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
        onExited: function(exitCode, exitStatus) {
            if (!root.batteryPath) {
                batteryLabel.text = "🔋 ?";
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

    function updateBatteryTooltip() {
        // Combines the live charge reading with the last known health
        // reading into a single tooltip on the battery icon.
        var health = root.batteryHealthText !== "" ? root.batteryHealthText : "checking…";
        batteryLabel.tooltipText = batteryLabel.chargeText + "\nBattery health: " + health;
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
                if (status === "Charging") icon = "🔋";
                else if (status === "Discharging") icon = "🔋";
                else if (status === "Full") icon = "🔋";
                batteryLabel.text = icon + " " + cap + "%";
                batteryLabel.chargeText = "Battery charge: " + cap + "% (" + status + ")";
                updateBatteryTooltip();
            }
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) batteryLabel.text = "🔋 ?";
        }
    }

    function updateHealth() {
        if (!root.batteryPath) return;
        healthProc.command = ["sh", "-c",
            // Prefer charge_* (Ah-based fuel gauges). Some batteries only
            // expose energy_* (Wh-based) instead - that's the "condition"
            // figure inxi reports - so fall back to those if charge_full
            // is missing or zero.
            "full=$(cat " + root.batteryPath + "/charge_full 2>/dev/null || echo 0); " +
            "design=$(cat " + root.batteryPath + "/charge_full_design 2>/dev/null || echo 0); " +
            "if [ \"$full\" -eq 0 ] || [ \"$design\" -eq 0 ]; then " +
            "  full=$(cat " + root.batteryPath + "/energy_full 2>/dev/null || echo 0); " +
            "  design=$(cat " + root.batteryPath + "/energy_full_design 2>/dev/null || echo 0); " +
            "fi; " +
            "if [ \"$design\" -gt 0 ]; then echo $(( full * 100 / design )); else echo 0; fi"
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
                    root.batteryHealthText = health + "%";
                } else {
                    root.batteryHealthText = "unknown";
                }
                updateBatteryTooltip();
            }
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                root.batteryHealthText = "unknown";
                updateBatteryTooltip();
            }
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
                    limitLabel.text = "🧢 " + limit + "%";
                    limitLabel.visible = true;
                } else {
                    limitLabel.visible = false;
                }
            }
        }
        onExited: function(exitCode, exitStatus) {
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
