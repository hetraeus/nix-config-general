import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    required property var desktop
    required property var browser

    width: parent.width * 0.43
    height: parent.height * 0.45
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: parent.width * 0.1
    anchors.bottomMargin: 108
    z: 1

    visible: previewPath !== ""

    color: Qt.rgba(desktop.base01.r, desktop.base01.g, desktop.base01.b, 0.88)
    border.color: Qt.rgba(desktop.base04.r, desktop.base04.g, desktop.base04.b, 0.12)
    border.width: 1
    radius: 0

    property string previewPath: ""
    property string previewContent: ""
    property string pendingCheckPath: ""

    function updatePreview() {
        var selected = desktop.fileGrid.selectedPaths;
        if (selected.length > 0) {
            root.pendingCheckPath = selected[0];
            checkMimeProc.command = ["sh", "-c",
                "file -b --mime-type " + shellQuote(root.pendingCheckPath) + " 2>/dev/null || echo unknown"
            ];
            checkMimeProc.running = true;
            return;
        }
        root.tryFallback();
    }

    function tryFallback() {
        root.pendingCheckPath = "";
        findFallbackProc.command = ["sh", "-c",
            "cd " + shellQuote(browser.currentPath) + " && " +
            "for want in readme.md readme.asciidoc readme.adoc readme.txt readme.rst readme.markdown readme; do " +
            "  for f in README*; do " +
            "    [ -f \"$f\" ] || continue; " +
            "    lf=$(echo \"$f\" | tr '[:upper:]' '[:lower:]'); " +
            "    [ \"$lf\" = \"$want\" ] && { echo \"$f\"; exit 0; }; " +
            "  done; " +
            "done; " +
            "if [ -f flake.nix ]; then echo flake.nix; else echo ''; fi"
        ];
        findFallbackProc.running = true;
    }

    function shellQuote(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }

    Process {
        id: checkMimeProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var mime = text.trim();
                var isText = false;

                if (mime === "unknown" || mime === "") {
                    var ext = root.pendingCheckPath.split('.').pop().toLowerCase();
                    var textExts = ["md", "asciidoc", "adoc", "txt", "rst", "nix",
                                    "qml", "js", "py", "sh", "c", "h", "cpp", "hpp",
                                    "rs", "go", "yaml", "yml", "toml", "json", "xml",
                                    "css", "html", "vim", "lua"];
                    isText = textExts.indexOf(ext) >= 0;
                } else {
                    isText = mime.startsWith("text/") ||
                             mime.indexOf("json") >= 0 ||
                             mime.indexOf("nix") >= 0 ||
                             mime.indexOf("script") >= 0;
                }

                if (isText) {
                    root.previewPath = root.pendingCheckPath;
                    readProc.command = ["head", "-n", "200", root.previewPath];
                    readProc.running = true;
                } else {
                    root.previewPath = "";
                    root.previewContent = "";
                    root.tryFallback();
                }
            }
        }
    }

    Process {
        id: findFallbackProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var fallback = text.trim();
                if (fallback) {
                    root.previewPath = browser.currentPath + "/" + fallback;
                    readProc.command = ["head", "-n", "200", root.previewPath];
                    readProc.running = true;
                } else {
                    root.previewPath = "";
                    root.previewContent = "";
                }
            }
        }
    }

    Process {
        id: readProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.previewContent = text;
            }
        }
    }

    Connections {
        target: root.desktop.fileGrid
        function onSelectedPathsChanged() {
            root.updatePreview();
        }
    }

    Connections {
        target: root.browser
        function onCurrentPathChanged() {
            root.updatePreview();
        }
    }

    Component.onCompleted: {
        root.updatePreview();
    }

    // ── UI ──
    Column {
        anchors.fill: parent
        anchors.margins: 14
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 6

        Label {
            id: filenameLabel
            text: root.previewPath ? root.browser.basename(root.previewPath) : ""
            textFormat: Text.PlainText
            color: desktop.base04
            font.pixelSize: 16
            font.weight: Font.Bold
            elide: Text.ElideMiddle
            width: parent.width
        }

        Rectangle {
            id: separator
            width: parent.width
            height: 1
            color: Qt.rgba(desktop.base04.r, desktop.base04.g, desktop.base04.b, 0.12)
        }

        Flickable {
            width: parent.width
            height: parent.height - filenameLabel.height - separator.height - parent.spacing * 2
            contentWidth: textContent.width
            contentHeight: textContent.height
            clip: true

            Label {
                id: textContent
                text: root.previewContent
                textFormat: Text.PlainText
                color: desktop.base04
                font.pixelSize: 15
                font.family: "monospace"
                width: root.width - 32
                wrapMode: Text.Wrap
                lineHeight: 1.4
                lineHeightMode: Text.ProportionalHeight
            }
        }
    }
}
