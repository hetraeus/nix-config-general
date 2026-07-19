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
    property bool pendingIsDir: false

    // Priority-ordered list of README filenames (lowercased for matching).
    // The shell script will do case-insensitive matching against these.
    property var readmePriority: [
        "readme.md", "readme.txt", "readme.asciidoc", "readme.adoc",
        "readme.rst", "readme.markdown", "readme", "readme.org",
        "readme.pod", "readme.tex"
    ]

    // Second-choice files when no README is found.
    property var secondChoicePriority: [
        "flake.nix", "changelog.md", "changelog", "changelog.txt",
        "changes.md", "changes", "changes.txt", "news.md", "news", "news.txt",
        "license", "license.md", "license.txt", "copying",
        "contributing.md", "contributing", "package.json", "cargo.toml",
        "setup.py", "pyproject.toml", "go.mod", "makefile", "cmakelists.txt",
        "configure", "meson.build", "build.zig"
    ]

    function updatePreview() {
        var selected = desktop.fileGrid.selectedPaths;
        if (selected.length > 0) {
            root.pendingCheckPath = selected[0];
            // First: determine if the selected path is a directory
            // (handles real directories and symlinks to directories)
            checkDirProc.command = ["sh", "-c",
                "if [ -d " + shellQuote(root.pendingCheckPath) + " ]; then echo dir; else echo file; fi"
            ];
            checkDirProc.running = true;
            return;
        }
        root.tryFallback();
    }

    function tryFallback() {
        root.pendingCheckPath = "";
        root.pendingIsDir = false;
        findFallbackProc.command = ["sh", "-c",
            "cd " + shellQuote(browser.currentPath) + " && " +
            root.buildFindScript()
        ];
        findFallbackProc.running = true;
    }

    function tryDirPreview(dirPath) {
        findDirProc.command = ["sh", "-c",
            "cd " + shellQuote(dirPath) + " && " +
            root.buildFindScript()
        ];
        findDirProc.running = true;
    }

    // Build a shell script that searches for READMEs then second-choices
    // in the current working directory (which the caller cd's into).
    function buildFindScript() {
        var script = '';

        // Search README* files in priority order
        for (var i = 0; i < readmePriority.length; i++) {
            var want = readmePriority[i];
            script +=
                'for f in README*; do ' +
                '  [ -f "$f" ] || continue; ' +
                '  lf=$(echo "$f" | tr \'[:upper:]\' \'[:lower:]\'); ' +
                '  [ "$lf" = "' + want + '" ] && { echo "$f"; exit 0; }; ' +
                'done; ';
        }

        // Search second-choice files in priority order
        for (var j = 0; j < secondChoicePriority.length; j++) {
            var want2 = secondChoicePriority[j];
            script +=
                'for f in *; do ' +
                '  [ -f "$f" ] || continue; ' +
                '  lf=$(echo "$f" | tr \'[:upper:]\' \'[:lower:]\'); ' +
                '  [ "$lf" = "' + want2 + '" ] && { echo "$f"; exit 0; }; ' +
                'done; ';
        }

        script += 'echo \'\';';
        return script;
    }

    function shellQuote(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }

    Process {
        id: checkDirProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var result = text.trim();
                if (result === "dir") {
                    root.pendingIsDir = true;
                    root.tryDirPreview(root.pendingCheckPath);
                } else {
                    root.pendingIsDir = false;
                    // It's a file — check MIME type as before
                    checkMimeProc.command = ["sh", "-c",
                        "file -b --mime-type " + shellQuote(root.pendingCheckPath) + " 2>/dev/null || echo unknown"
                    ];
                    checkMimeProc.running = true;
                }
            }
        }
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
                                    "css", "html", "vim", "lua", "zig", "nix"];
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
        id: findDirProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var found = text.trim();
                if (found) {
                    root.previewPath = root.pendingCheckPath + "/" + found;
                    readProc.command = ["head", "-n", "200", root.previewPath];
                    readProc.running = true;
                } else {
                    // Directory has no README or second-choice file
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
