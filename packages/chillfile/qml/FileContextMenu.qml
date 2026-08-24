import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Menu {
    id: contextMenu

    required property var desktop

    property string filePath: ""
    property string fileName: ""
    property bool isDir: false

    onAboutToShow: {
        console.log("[FileContextMenu] loader.item:", nemoActionsLoader.item,
            "loader.status:", nemoActionsLoader.status,
            "loaded:", nemoActionsLoader.item ? nemoActionsLoader.item.loaded : "n/a",
            "actionsCount:", nemoActionsLoader.item ? nemoActionsLoader.item.actions.length : "n/a");
        if (nemoActionsLoader.item) {
            var applicable = nemoActionsLoader.item.getApplicableActions(
                desktop.fileGrid.selectedPaths, filePath, isDir
            );
            console.log("[FileContextMenu] applicable actions:", applicable.length,
                "selectedPaths:", JSON.stringify(desktop.fileGrid.selectedPaths),
                "filePath:", filePath, "isDir:", isDir);
            nemoActionsRepeater.model = applicable;
        } else {
            nemoActionsRepeater.model = [];
        }
    }

    MenuItem {
        text: "Copy Path"
        font.pixelSize: 15
        onTriggered: {
            var selected = contextMenu.desktop.fileGrid.selectedPaths;
            var paths = selected.length > 0 ? selected : [contextMenu.filePath];
            contextMenu.desktop.copyToClipboard(paths.join("\n"));
        }
    }

    MenuItem {
        text: "Rename"
        font.pixelSize: 15
        onTriggered: {
            contextMenu.desktop.fileGrid.renamingPath = contextMenu.filePath;
        }
    }

    MenuItem {
        text: "Open Terminal Here"
        font.pixelSize: 15
        visible: contextMenu.isDir
        onTriggered: {
            contextMenu.desktop.runTerminal(["kitty", "--directory", contextMenu.filePath]);
        }
    }

    MenuItem {
        text: "Open Externally"
        font.pixelSize: 15
        visible: !contextMenu.isDir
        onTriggered: {
            contextMenu.desktop.openFile(contextMenu.filePath);
        }
    }

    MenuSeparator {
        visible: nemoActionsRepeater.count > 0
    }

    Repeater {
        id: nemoActionsRepeater
        model: []

        MenuItem {
            text: modelData.name
            font.pixelSize: 15
            onTriggered: {
                if (!nemoActionsLoader.item) return;
                var cmd = nemoActionsLoader.item.buildExecCommand(
                    modelData.exec,
                    contextMenu.desktop.fileGrid.selectedPaths,
                    contextMenu.filePath
                );
                nemoRunProc.command = ["sh", "-c", cmd];
                nemoRunProc.running = true;
            }
        }
    }

    Loader {
        id: nemoActionsLoader
        source: "NemoActions.qml"
        active: true
        asynchronous: false
    }

    Process {
        id: nemoRunProc
        running: false
    }

    MenuSeparator {}

    MenuItem {
        text: "Copy Name"
        font.pixelSize: 15
        onTriggered: {
            contextMenu.desktop.copyToClipboard(contextMenu.fileName);
        }
    }
}
