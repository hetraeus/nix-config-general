import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    WlrLayershell.layer: WlrLayer.Background

    // ── empty-workspace focus fix ──
    // ATTEMPT: dynamically binding keyboardFocus to Exclusive/OnDemand
    // based on Hyprland.activeToplevel. REVERTED — Exclusive doesn't
    // reliably release once granted (matches hyprwm/Hyprland#8293,
    // "Changing layer shell interactivity doesn't release keyboard
    // focus"): since this background layer is always mapped, once it
    // grabbed Exclusive it could permanently block every other window
    // from becoming focused again, regardless of the binding flipping
    // back to OnDemand. Back to static OnDemand so window switching
    // works normally; the empty-workspace refocus problem is still
    // unresolved (see conversation for what's been ruled out so far:
    // hyprctl cursor warp, wlr-virtual-pointer motion, wlr-virtual-pointer
    // click, and layer-interactivity toggling have all failed).
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    focusable: true

    color: "transparent"

    property color base01: "#2c393f"
    property color base03: "#707880"
    property color base04: "#c9ccd3"

    property alias browser: fileBrowser
    property alias fileGrid: fileGrid
    property alias bottomBar: bottomBar
    property alias contextMenu: contextMenu

    // Set to true to re-enable [focus-fix] debug logging when
    // investigating the empty-workspace keyboard focus issue.
    property bool debugFocus: false

    // Best-effort: at least keep the Qt-side focus item as fileGrid when
    // landing on an empty workspace, in case OnDemand does get granted
    // through some path we haven't identified yet (manual mouse jiggle
    // still being the reliable one for now).
    Connections {
        target: Hyprland
        function onActiveToplevelChanged() {
            if (root.debugFocus) console.log("[focus-fix] activeToplevelChanged, activeToplevel=", Hyprland.activeToplevel);
            if (!Hyprland.activeToplevel) fileGrid.forceActiveFocus();
        }
        function onFocusedWorkspaceChanged() {
            if (root.debugFocus) console.log("[focus-fix] focusedWorkspaceChanged, activeToplevel=", Hyprland.activeToplevel);
            if (!Hyprland.activeToplevel) fileGrid.forceActiveFocus();
        }
    }

    FileBrowser {
        id: fileBrowser
    }

    Wallpaper {}

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: fileGrid.selectedPaths = []
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        anchors.topMargin: 8
        z: 0

        FileGrid {
            id: fileGrid
            browser: fileBrowser
            desktop: root
        }

        BottomBar {
            id: bottomBar
            browser: fileBrowser
            desktop: root
        }
    }

    TextPreview {
        id: textPreview
        desktop: root
        browser: fileBrowser
    }

    FileContextMenu {
        id: contextMenu
        desktop: root
    }

    DesktopShortcuts {
        browser: fileBrowser
        desktop: root
    }

    Process {
        id: termProc
        running: false
    }

    Process {
        id: copyProc
        running: false
    }

    Process {
        id: renameProc
        running: false
    }

    // NEW: notification process
    Process {
        id: notifyProc
        running: false
    }

    Timer {
        id: refreshTimer
        interval: 100
        onTriggered: fileBrowser.lsProc.running = true
    }

    Process {
        id: paletteProc
        running: false
        command: ["cat", Quickshell.env("HOME") + "/.config/stylix/palette.json"]
        stdout: StdioCollector {
            onStreamFinished: root.loadPalette(text)
        }
    }

    function loadPalette(raw) {
        var palette;
        try {
            palette = JSON.parse(raw);
        } catch (e) {
            console.log("Failed to parse stylix palette:", e);
            return;
        }
        if (palette.base01) root.base01 = "#" + palette.base01;
        if (palette.base03) root.base03 = "#" + palette.base03;
        if (palette.base04) root.base04 = "#" + palette.base04;
    }

    function runTerminal(args) {
        termProc.command = args;
        termProc.running = true;
    }

    function copyToClipboard(text) {
        copyProc.command = ["wl-copy", text];
        copyProc.running = true;
    }

    function renamePath(oldPath, newPath) {
        renameProc.command = ["mv", oldPath, newPath];
        renameProc.running = true;
        refreshTimer.start();
    }

    // NEW: copy selected paths + show notification
    function copySelectedPathsWithNotification() {
        var selected = fileGrid.selectedPaths;
        if (selected.length === 0) return;

        var text = selected.join("\n");
        copyToClipboard(text);

        var title = selected.length === 1 ? "Copied path" : "Copied " + selected.length + " paths";
        var body;
        if (selected.length === 1) {
            body = selected[0];
        } else {
            body = selected.slice(0, 5).join("\n");
            if (selected.length > 5) body += "\n… and " + (selected.length - 5) + " more";
        }

        notifyProc.command = ["notify-send", "-a", "quickshell", title, body];
        notifyProc.running = true;
    }

    Component.onCompleted: {
        paletteProc.running = true;
        fileGrid.forceActiveFocus();
    }
}
