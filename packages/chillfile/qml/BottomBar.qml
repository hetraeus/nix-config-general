import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: bottomBar

    required property var browser
    required property var desktop

    property alias searchField: searchField

    Layout.fillWidth: true
    implicitHeight: 54

    function clearSearch() {
        searchField.text = "";
        browser.filterText = "";
    }

    function focusSearchWith(text) {
        searchField.forceActiveFocus();
        searchField.text = text;
        searchField.cursorPosition = searchField.text.length;
        browser.filterText = searchField.text;
    }

    Connections {
        target: bottomBar.browser
        function onNavigated() {
            bottomBar.browser.suppressTextFilter = true;
            searchField.text = "";
            bottomBar.browser.suppressTextFilter = false;
            bottomBar.desktop.fileGrid.forceActiveFocus();
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 12

        ClockWidget {}

        GitStatus {
            id: gitStatus
            currentDir: bottomBar.browser.currentPath
            bgColor: bottomBar.desktop.base01
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Button {
            id: backButton
            text: "🢀"
            enabled: bottomBar.browser.navStack.length > 1
            rightPadding: 4

            contentItem: Label {
                text: parent.text
                color: "white"
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: parent.enabled
                    ? (parent.hovered ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.1))
                    : Qt.rgba(1,1,1,0.05)
                border.color: Qt.rgba(1,1,1,0.18)
                border.width: 1
                radius: 999
                implicitWidth: 38
                implicitHeight: 38
            }

            onClicked: bottomBar.browser.goUp()
        }

        TextField {
            id: searchField
            placeholderText: "Filter " + bottomBar.browser.basename(bottomBar.browser.currentPath) + "…"
            placeholderTextColor: bottomBar.desktop.base03
            Layout.minimumWidth: 330
            Layout.preferredWidth: Math.max(330, placeholderMetrics.width + 40)
            color: bottomBar.desktop.base04
            font.pixelSize: 15
            horizontalAlignment: Text.AlignHCenter
            leftPadding: 10
            rightPadding: 10

            background: Rectangle {
                color: bottomBar.desktop.base01
                border.color: parent.activeFocus
                    ? Qt.rgba(100,160,255,0.7)
                    : Qt.rgba(255,255,255,0.18)
                border.width: 1
                radius: 6
            }

            onTextChanged: {
                if (!bottomBar.browser.suppressTextFilter) {
                    bottomBar.browser.filterText = text;
                }
            }

            Keys.priority: Keys.BeforeItem
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Backspace && (event.modifiers & Qt.ShiftModifier)) {
                    event.accepted = true;
                    bottomBar.browser.goUp();
                    return;
                }
                if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Left) {
                    event.accepted = true;
                    bottomBar.browser.goUp();
                    return;
                }
                if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Right) {
                    event.accepted = true;
                    bottomBar.browser.historyForward();
                    return;
                }
                if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Up) {
                    event.accepted = true;
                    bottomBar.browser.goToParent();
                    return;
                }
                if ((event.key === Qt.Key_Left || event.key === Qt.Key_Right ||
                     event.key === Qt.Key_Up || event.key === Qt.Key_Down ||
                     event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) && text === "") {
                    event.accepted = true;
                    bottomBar.desktop.fileGrid.forceActiveFocus();
                    if (bottomBar.desktop.fileGrid.currentIndex < 0 && bottomBar.browser.filteredModel.count > 0) {
                        bottomBar.desktop.fileGrid.currentIndex = 0;
                        var item = bottomBar.browser.filteredModel.get(0);
                        bottomBar.desktop.fileGrid.selectedPaths = [item.path];
                        bottomBar.browser.lastFocusedPath = item.path;
                    }
                    return;
                }
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    event.accepted = true;
                    if (bottomBar.browser.filteredModel.count > 0) {
                        var first = bottomBar.browser.filteredModel.get(0);
                        if (first.isDir) {
                            bottomBar.browser.lastFocusedPath = first.path;
                            bottomBar.browser.navigateTo(first.path);
                        } else {
                            Qt.openUrlExternally("file://" + first.path);
                            bottomBar.clearSearch();
                        }
                    }
                    return;
                }
                if (event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    bottomBar.clearSearch();
                    bottomBar.desktop.fileGrid.forceActiveFocus();
                    return;
                }
            }

            TextMetrics {
                id: placeholderMetrics
                font: searchField.font
                text: searchField.placeholderText
            }
        }

        Button {
            id: searchModeButton
            text: bottomBar.browser.recursiveSearch ? "🌀" : "⌵"
            implicitWidth: searchField.implicitHeight + 2
            implicitHeight: searchField.implicitHeight + 2

            ToolTip {
                id: searchModeTip
                text: bottomBar.browser.recursiveSearch ? "Switch to flat filter" : "Switch to recursive filter"
                visible: false
                background: Rectangle {
                    color: bottomBar.desktop.base01
                    border.color: Qt.rgba(bottomBar.desktop.base04.r, bottomBar.desktop.base04.g, bottomBar.desktop.base04.b, 0.3)
                    border.width: 1
                    radius: 4
                }
                contentItem: Label {
                    text: searchModeTip.text
                    color: bottomBar.desktop.base04
                    font.pixelSize: 13
                }
            }

            Timer {
                id: searchModeTipTimer
                interval: 1500
                onTriggered: searchModeTip.visible = true
            }

            onHoveredChanged: {
                if (hovered) {
                    searchModeTipTimer.start();
                } else {
                    searchModeTipTimer.stop();
                    searchModeTip.visible = false;
                }
            }

            contentItem: Label {
                text: parent.text
                color: bottomBar.browser.recursiveSearch ? "#f9e2af" : "white"
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                implicitWidth: parent.implicitWidth
                implicitHeight: parent.implicitHeight
                color: parent.hovered ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.1)
                border.color: bottomBar.browser.recursiveSearch
                    ? Qt.rgba(249, 226, 175, 0.5)
                    : Qt.rgba(1,1,1,0.18)
                border.width: 1
                radius: width / 2
            }

            onClicked: {
                bottomBar.browser.recursiveSearch = !bottomBar.browser.recursiveSearch;
                if (bottomBar.browser.filterText !== "") {
                    bottomBar.browser.applyFilter();
                }
                bottomBar.desktop.fileGrid.forceActiveFocus();
            }
        }

        Button {
            id: edirButton
            text: "⌯"
            implicitWidth: searchField.implicitHeight + 2
            implicitHeight: searchField.implicitHeight + 2

            ToolTip {
                id: edirTip
                text: "Open edir here"
                visible: false
                background: Rectangle {
                    color: bottomBar.desktop.base01
                    border.color: Qt.rgba(bottomBar.desktop.base04.r, bottomBar.desktop.base04.g, bottomBar.desktop.base04.b, 0.3)
                    border.width: 1
                    radius: 4
                }
                contentItem: Label {
                    text: edirTip.text
                    color: bottomBar.desktop.base04
                    font.pixelSize: 13
                }
            }

            Timer {
                id: edirTipTimer
                interval: 1500
                onTriggered: edirTip.visible = true
            }

            onHoveredChanged: {
                if (hovered) {
                    edirTipTimer.start();
                } else {
                    edirTipTimer.stop();
                    edirTip.visible = false;
                }
            }

            contentItem: Label {
                text: parent.text
                color: "white"
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                implicitWidth: parent.implicitWidth
                implicitHeight: parent.implicitHeight
                color: parent.hovered ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.1)
                border.color: Qt.rgba(1,1,1,0.18)
                border.width: 1
                radius: width / 2
            }

            onClicked: {
                bottomBar.desktop.runTerminal(["kitty", "--directory", bottomBar.browser.currentPath, "edir"]);
            }
        }

        Button {
            id: homeButton
            text: "☉"
            implicitWidth: searchField.implicitHeight + 2
            implicitHeight: searchField.implicitHeight + 2

            ToolTip {
                id: homeTip
                text: "Go to home"
                visible: false
                background: Rectangle {
                    color: bottomBar.desktop.base01
                    border.color: Qt.rgba(bottomBar.desktop.base04.r, bottomBar.desktop.base04.g, bottomBar.desktop.base04.b, 0.3)
                    border.width: 1
                    radius: 4
                }
                contentItem: Label {
                    text: homeTip.text
                    color: bottomBar.desktop.base04
                    font.pixelSize: 13
                }
            }

            Timer {
                id: homeTipTimer
                interval: 1500
                onTriggered: homeTip.visible = true
            }

            onHoveredChanged: {
                if (hovered) {
                    homeTipTimer.start();
                } else {
                    homeTipTimer.stop();
                    homeTip.visible = false;
                }
            }

            contentItem: Label {
                text: parent.text
                color: "white"
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                implicitWidth: parent.implicitWidth
                implicitHeight: parent.implicitHeight
                color: parent.hovered ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.1)
                border.color: Qt.rgba(1,1,1,0.18)
                border.width: 1
                radius: width / 2
            }

            onClicked: bottomBar.browser.navigateTo(bottomBar.browser.initialPath)
        }

        Button {
            id: shareButton
            text: "󰒗"
            implicitWidth: searchField.implicitHeight + 2
            implicitHeight: searchField.implicitHeight + 2

            ToolTip {
                id: shareTip
                text: "Share selected files"
                visible: false
                background: Rectangle {
                    color: bottomBar.desktop.base01
                    border.color: Qt.rgba(bottomBar.desktop.base04.r, bottomBar.desktop.base04.g, bottomBar.desktop.base04.b, 0.3)
                    border.width: 1
                    radius: 4
                }
                contentItem: Label {
                    text: shareTip.text
                    color: bottomBar.desktop.base04
                    font.pixelSize: 13
                }
            }

            Timer {
                id: shareTipTimer
                interval: 1500
                onTriggered: shareTip.visible = true
            }

            onHoveredChanged: {
                if (hovered) {
                    shareTipTimer.start();
                } else {
                    shareTipTimer.stop();
                    shareTip.visible = false;
                }
            }

            contentItem: Label {
                text: parent.text
                color: "white"
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: -1
                anchors.verticalCenter: parent.verticalCenter
            }

            background: Rectangle {
                implicitWidth: parent.implicitWidth
                implicitHeight: parent.implicitHeight
                color: parent.hovered ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.1)
                border.color: Qt.rgba(1,1,1,0.18)
                border.width: 1
                radius: width / 2
            }

            onClicked: {
                if (bottomBar.desktop.fileGrid.selectedPaths.length === 0) return;
                var args = ["kitty", "--directory", bottomBar.browser.currentPath, "fmenu-share"];
                for (var i = 0; i < bottomBar.desktop.fileGrid.selectedPaths.length; i++) {
                    args.push(bottomBar.desktop.fileGrid.selectedPaths[i]);
                }
                bottomBar.desktop.runTerminal(args);
            }
        }
    }
}
