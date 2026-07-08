import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color: "transparent"

    property color base01: "#2c393f"
    property color base03: "#707880"
    property color base04: "#c9ccd3"

    property alias browser: fileBrowser
    property alias fileGrid: fileGrid
    property alias bottomBar: bottomBar
    property alias contextMenu: contextMenu

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

    Component.onCompleted: {
        paletteProc.running = true;
        fileGrid.forceActiveFocus();
    }
}
