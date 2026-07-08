import QtQuick.Controls

Menu {
    id: contextMenu

    required property var desktop  // root Desktop.qml instance (shared utilities)

    property string filePath: ""
    property string fileName: ""
    property bool isDir: false

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
        // The only place in the file manager that can reach the network -
        // hands the file to the system's default app for its type, which
        // may itself make network requests (e.g. resolving remote
        // includes/links). Deliberately opt-in, never the default action.
        text: "Open Externally"
        font.pixelSize: 15
        visible: !contextMenu.isDir
        onTriggered: {
            Qt.openUrlExternally("file://" + contextMenu.filePath);
        }
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
