import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// The desktop's file grid: renders the current (filtered) directory
// listing, owns click/keyboard-driven selection, and handles in-place
// renaming.
GridView {
    id: gridView

    required property var browser  // FileBrowser instance (navigation + listing)
    required property var desktop  // root Desktop.qml instance (shared utilities)

    property var selectedPaths: []
    property string renamingPath: ""

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.maximumWidth: 2 * cellWidth + leftMargin
    Layout.alignment: Qt.AlignLeft
    cellWidth: 280
    cellHeight: 84
    clip: true
    focus: true
    model: browser.filteredModel
    leftMargin: 14

    function openPath(path) {
        Qt.openUrlExternally("file://" + path);
    }

    function startRenameAtCurrent() {
        var idx = gridView.currentIndex >= 0 ? gridView.currentIndex : 0;
        if (idx >= 0 && idx < browser.filteredModel.count) {
            var item = browser.filteredModel.get(idx);
            gridView.renamingPath = item.path;
        }
    }

    function selectAllVisible() {
        var paths = [];
        for (var i = 0; i < browser.filteredModel.count; i++) {
            paths.push(browser.filteredModel.get(i).path);
        }
        gridView.selectedPaths = paths;
        if (browser.filteredModel.count > 0) {
            gridView.currentIndex = browser.filteredModel.count - 1;
            browser.lastFocusedPath = browser.filteredModel.get(browser.filteredModel.count - 1).path;
            gridView.applyScrolloff();
        }
    }

    property int scrolloffRows: 2

    // Keep the current item at least 'scrolloffRows' away from the
    // top and bottom edges of the viewport, like vim's 'scrolloff'.
    function applyScrolloff() {
        var idx = gridView.currentIndex;
        if (idx < 0 || browser.filteredModel.count === 0) return;

        var cols = Math.max(1, Math.floor(gridView.width / gridView.cellWidth));
        var row = Math.floor(idx / cols);
        var totalRows = Math.max(1, Math.ceil(browser.filteredModel.count / cols));
        var viewH = gridView.height;
        var so = gridView.scrolloffRows;
        var ch = gridView.cellHeight;

        // Target top-of-viewport to keep 'so' rows above cursor
        var minY = (row - so) * ch;
        // Target top-of-viewport to keep 'so' rows below cursor
        var maxY = (row + so + 1) * ch - viewH;

        var newY = gridView.contentY;
        if (newY > minY) newY = minY;
        if (newY < maxY) newY = maxY;

        // Clamp to valid scroll range
        var absoluteMaxY = Math.max(0, totalRows * ch - viewH);
        newY = Math.max(0, Math.min(absoluteMaxY, newY));

        gridView.contentY = newY;
    }

    // Whenever the browser rebuilds filteredModel, decide which row should
    // end up focused (previously-focused path if still present, else the
    // first row).
    Connections {
        target: gridView.browser
        function onFilterApplied() {
            var i;
            if (gridView.browser.lastFocusedPath) {
                for (i = 0; i < gridView.browser.filteredModel.count; i++) {
                    if (gridView.browser.filteredModel.get(i).path === gridView.browser.lastFocusedPath) {
                        gridView.currentIndex = i;
                        var item = gridView.browser.filteredModel.get(i);
                        gridView.selectedPaths = [item.path];
                        Qt.callLater(function() { gridView.applyScrolloff(); });
                        return;
                    }
                }
            }
            if (gridView.browser.filteredModel.count > 0) {
                gridView.currentIndex = 0;
                var firstItem = gridView.browser.filteredModel.get(0);
                gridView.selectedPaths = [firstItem.path];
                gridView.browser.lastFocusedPath = firstItem.path;
                Qt.callLater(function() { gridView.applyScrolloff(); });
            } else {
                gridView.currentIndex = -1;
                gridView.selectedPaths = [];
            }
        }
    }

    Keys.onPressed: function(event) {
        if (gridView.renamingPath !== "") {
            event.accepted = false;
            return;
        }

        if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Left) {
            event.accepted = true;
            browser.goUp();
            return;
        }
        if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Right) {
            event.accepted = true;
            browser.historyForward();
            return;
        }
        if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Up) {
            event.accepted = true;
            browser.goToParent();
            return;
        }

        if (event.text && event.text.length === 1 && /[a-zA-Z0-9]/.test(event.text)) {
            event.accepted = true;
            desktop.bottomBar.focusSearchWith(event.text);
            return;
        }

        var idx = gridView.currentIndex;
        var cols = Math.max(1, Math.floor(gridView.width / gridView.cellWidth));
        var count = browser.filteredModel.count;

        if (event.key === Qt.Key_Left) {
            event.accepted = true;
            if (idx > 0) {
                gridView.currentIndex = idx - 1;
                var item = browser.filteredModel.get(gridView.currentIndex);
                gridView.selectedPaths = [item.path];
                browser.lastFocusedPath = item.path;
                gridView.applyScrolloff();
            }
        } else if (event.key === Qt.Key_Right) {
            event.accepted = true;
            if (idx >= 0 && idx < count - 1) {
                gridView.currentIndex = idx + 1;
                var item = browser.filteredModel.get(gridView.currentIndex);
                gridView.selectedPaths = [item.path];
                browser.lastFocusedPath = item.path;
                gridView.applyScrolloff();
            }
        } else if (event.key === Qt.Key_Up) {
            event.accepted = true;
            if (idx - cols >= 0) {
                gridView.currentIndex = idx - cols;
                var item = browser.filteredModel.get(gridView.currentIndex);
                gridView.selectedPaths = [item.path];
                browser.lastFocusedPath = item.path;
                gridView.applyScrolloff();
            }
        } else if (event.key === Qt.Key_Down) {
            event.accepted = true;
            if (idx >= 0 && idx + cols < count) {
                gridView.currentIndex = idx + cols;
                var item = browser.filteredModel.get(gridView.currentIndex);
                gridView.selectedPaths = [item.path];
                browser.lastFocusedPath = item.path;
                gridView.applyScrolloff();
            }
        } else if (event.key === Qt.Key_PageUp) {
            event.accepted = true;
            if (idx < 0) {
                if (count > 0) {
                    gridView.currentIndex = 0;
                    var item = browser.filteredModel.get(0);
                    gridView.selectedPaths = [item.path];
                    browser.lastFocusedPath = item.path;
                    gridView.applyScrolloff();
                }
            } else {
                var visibleRows = Math.max(1, Math.floor(gridView.height / gridView.cellHeight));
                var currentRow = Math.floor(idx / cols);
                var currentCol = idx % cols;
                var newRow = Math.max(0, currentRow - visibleRows);
                var newIdx = newRow * cols + currentCol;
                if (newIdx >= count) newIdx = count - 1;
                gridView.currentIndex = newIdx;
                var item = browser.filteredModel.get(newIdx);
                gridView.selectedPaths = [item.path];
                browser.lastFocusedPath = item.path;
                gridView.applyScrolloff();
            }
        } else if (event.key === Qt.Key_PageDown) {
            event.accepted = true;
            if (idx < 0) {
                if (count > 0) {
                    gridView.currentIndex = 0;
                    var item = browser.filteredModel.get(0);
                    gridView.selectedPaths = [item.path];
                    browser.lastFocusedPath = item.path;
                    gridView.applyScrolloff();
                }
            } else {
                var visibleRows = Math.max(1, Math.floor(gridView.height / gridView.cellHeight));
                var currentRow = Math.floor(idx / cols);
                var currentCol = idx % cols;
                var lastRow = Math.floor((count - 1) / cols);
                var newRow = Math.min(lastRow, currentRow + visibleRows);
                var newIdx = newRow * cols + currentCol;
                if (newIdx >= count) newIdx = count - 1;
                gridView.currentIndex = newIdx;
                var item = browser.filteredModel.get(newIdx);
                gridView.selectedPaths = [item.path];
                browser.lastFocusedPath = item.path;
                gridView.applyScrolloff();
            }
        } else if (event.key === Qt.Key_F2) {
            event.accepted = true;
            gridView.startRenameAtCurrent();
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            event.accepted = true;
            var targetIdx = (idx >= 0) ? idx : 0;
            if (targetIdx >= 0 && targetIdx < count) {
                var item = browser.filteredModel.get(targetIdx);
                if (item.isDir) {
                    browser.lastFocusedPath = item.path;
                    browser.navigateTo(item.path);
                } else {
                    gridView.openPath(item.path);
                    desktop.bottomBar.clearSearch();
                }
            }
        } else if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
            event.accepted = true;
            gridView.selectAllVisible();
        }
    }

    delegate: FileItem {
        width: gridView.cellWidth
        height: gridView.cellHeight
        fileName: model.name
        filePath: model.path
        isDir: model.isDir
        iconPath: model.iconPath || ""
        isSelected: gridView.selectedPaths.indexOf(model.path) >= 0
        renaming: gridView.renamingPath === model.path
        renameBgColor: gridView.desktop.base01

        onClicked: function(mouse) {
            gridView.currentIndex = index;
            gridView.forceActiveFocus();

            if (mouse.modifiers & Qt.ControlModifier) {
                var newSel = gridView.selectedPaths.slice();
                var selIdx = newSel.indexOf(model.path);
                if (selIdx >= 0) newSel.splice(selIdx, 1);
                else newSel.push(model.path);
                gridView.selectedPaths = newSel;
            } else {
                gridView.selectedPaths = [model.path];
            }
            gridView.browser.lastFocusedPath = model.path;
            gridView.applyScrolloff();
        }

        onDoubleClicked: {
            if (model.isDir) {
                gridView.browser.lastFocusedPath = model.path;
                gridView.browser.navigateTo(model.path);
            } else {
                gridView.openPath(model.path);
            }
        }

        onRightClicked: function(mouse) {
            gridView.desktop.contextMenu.filePath = model.path;
            gridView.desktop.contextMenu.fileName = model.name;
            gridView.desktop.contextMenu.isDir = model.isDir;
            gridView.desktop.contextMenu.popup();
        }

        onRenameCommitted: function(newName) {
            gridView.renamingPath = "";
            Qt.callLater(function() { gridView.forceActiveFocus(); });
            if (newName && newName !== model.name) {
                gridView.desktop.renamePath(model.path, gridView.browser.currentPath + "/" + newName);
            }
        }

        onRenameCancelled: {
            gridView.renamingPath = "";
            Qt.callLater(function() { gridView.forceActiveFocus(); });
        }
    }

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        LayoutMirroring.enabled: true
        LayoutMirroring.childrenInherit: false
    }

    // ── touchpad swipe gestures ──
    // Horizontal two-finger swipes navigate back/forward like a browser.
    // Swipe left-to-right (positive delta) = back  (goUp)
    // Swipe right-to-left (negative delta) = forward (historyForward)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton   // let clicks pass through to FileItem delegates
        z: 1

        property real accumulatedDeltaX: 0
        property real swipeThreshold: 200   // total horizontal ° to trigger

        Timer {
            id: swipeResetTimer
            interval: 300
            onTriggered: parent.accumulatedDeltaX = 0
        }

        onWheel: function(wheel) {
            // Only grab clearly horizontal swipes (horiz > 2× vert)
            if (Math.abs(wheel.angleDelta.x) <= Math.abs(wheel.angleDelta.y) * 2) {
                wheel.accepted = false;
                return;
            }

            var dx = wheel.angleDelta.x;

            // Reset if the user changes swipe direction
            if (accumulatedDeltaX > 0 && dx < 0) accumulatedDeltaX = 0;
            if (accumulatedDeltaX < 0 && dx > 0) accumulatedDeltaX = 0;

            accumulatedDeltaX += dx;
            swipeResetTimer.restart();

            if (accumulatedDeltaX > swipeThreshold) {
                // left-to-right swipe → back
                gridView.browser.goUp();
                accumulatedDeltaX = 0;
            } else if (accumulatedDeltaX < -swipeThreshold) {
                // right-to-left swipe → forward
                gridView.browser.historyForward();
                accumulatedDeltaX = 0;
            }

            wheel.accepted = true;
        }
    }
}
