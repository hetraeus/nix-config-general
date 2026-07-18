import QtQuick

Item {
    id: root

    required property var browser
    required property var desktop

    Shortcut {
        sequence: "Backspace"
        enabled: !root.desktop.bottomBar.searchField.activeFocus && root.desktop.fileGrid.renamingPath === ""
        onActivated: root.browser.goUp()
    }

    Shortcut {
        sequence: "Shift+Backspace"
        enabled: root.desktop.fileGrid.renamingPath === ""
        onActivated: root.browser.goUp()
    }

    Shortcut {
        sequence: "Alt+Left"
        enabled: root.desktop.fileGrid.renamingPath === ""
        onActivated: root.browser.goUp()
    }

    Shortcut {
        sequence: "Alt+Right"
        enabled: root.desktop.fileGrid.renamingPath === ""
        onActivated: root.browser.historyForward()
    }

    Shortcut {
        sequence: "Alt+Up"
        enabled: root.desktop.fileGrid.renamingPath === ""
        onActivated: root.browser.goToParent()
    }

    Shortcut {
        sequence: "Ctrl+F"
        onActivated: {
            root.desktop.bottomBar.searchField.forceActiveFocus();
            root.desktop.bottomBar.searchField.selectAll();
        }
    }

    Shortcut {
        sequence: "F2"
        enabled: root.desktop.fileGrid.renamingPath === ""
        onActivated: root.desktop.fileGrid.startRenameAtCurrent()
    }

    Shortcut {
        sequence: "Tab"
        onActivated: {
            if (root.desktop.bottomBar.searchField.activeFocus) {
                root.desktop.fileGrid.forceActiveFocus();
            } else {
                root.desktop.bottomBar.searchField.forceActiveFocus();
                root.desktop.bottomBar.searchField.selectAll();
            }
        }
    }

    Shortcut {
        sequence: "F4"
        onActivated: {
            root.desktop.runTerminal(["kitty", "--directory", root.browser.currentPath]);
        }
    }

    // NEW: Ctrl+L — copy selected paths + notify
    Shortcut {
        sequence: "Ctrl+L"
        onActivated: root.desktop.copySelectedPathsWithNotification()
    }
}
