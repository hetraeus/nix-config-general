import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

RowLayout {
    id: gitRoot
    property string currentDir
    property color bgColor: "#1a1a2e"
    property var gitState: ({
        isRepo: false, branch: "", modified: 0, untracked: 0,
        staged: 0, deleted: 0, ahead: 0, behind: 0, stashed: 0
    })

    spacing: 8
    visible: gitState.isRepo

    Rectangle {
        color: gitRoot.bgColor
        border.color: Qt.rgba(255,255,255,0.15)
        border.width: 1
        radius: 6
        implicitHeight: 30
        implicitWidth: branchLabel.implicitWidth + iconsLabel.implicitWidth + 32

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 8

            Label {
                id: iconsLabel
                textFormat: Text.PlainText
                font.pixelSize: 14
            }

            Label {
                id: branchLabel
                textFormat: Text.PlainText
                color: Qt.rgba(0.71, 0.82, 1.0, 0.9)
                font.weight: Font.Bold
                font.pixelSize: 14
            }

        }
    }

    onCurrentDirChanged: refresh()

    Process {
        id: gitProc
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                parseGitOutput(text);
            }
        }
    }

    function refresh() {
        if (!currentDir) return;
        gitProc.command = ["sh", "-c",
            "git -C " + shellQuote(currentDir) + " status --porcelain=v1 -b --untracked-files=normal && echo '---STASH---' && git -C " + shellQuote(currentDir) + " stash list"];
        gitProc.running = true;
    }

    function shellQuote(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }

    function parseGitOutput(raw) {
        if (!raw || raw.indexOf("fatal") >= 0 || raw.indexOf("not a git repository") >= 0) {
            gitRoot.gitState = {
                isRepo: false, branch: "", modified: 0, untracked: 0,
                staged: 0, deleted: 0, ahead: 0, behind: 0, stashed: 0
            };
            updateDisplay();
            return;
        }

        var parts = raw.split("---STASH---");
        var statusRaw = parts[0];
        var stashRaw = parts.length > 1 ? parts[1] : "";

        var lines = statusRaw.split("\n");
        var branch = "";
        var modified = 0, untracked = 0, staged = 0, deleted = 0, ahead = 0, behind = 0;

        var i;
        for (i = 0; i < lines.length; i++) {
            var line = lines[i];
            if (line.startsWith("## ")) {
                var m = line.match(/^## ([^.]+)/);
                if (m) branch = m[1].split("...")[0];
                var am = line.match(/ahead (\d+)/);
                var bm = line.match(/behind (\d+)/);
                if (am) ahead = parseInt(am[1]);
                if (bm) behind = parseInt(bm[1]);
                continue;
            }
            if (line.length < 2) continue;
            var X = line[0];
            var Y = line[1];
            if (line.startsWith("??")) { untracked++; continue; }
            if (X !== " " && X !== "?") staged++;
            if (Y === "M" || Y === "T") modified++;
            if (Y === "D" || X === "D") deleted++;
        }

        var stashed = stashRaw.trim() === "" ? 0 : stashRaw.trim().split("\n").length;

        gitRoot.gitState = {
            isRepo: true,
            branch: branch,
            modified: modified,
            untracked: untracked,
            staged: staged,
            deleted: deleted,
            ahead: ahead,
            behind: behind,
            stashed: stashed
        };

        updateDisplay();
    }

    function updateDisplay() {
        if (!gitState.isRepo) { visible = false; return; }
        visible = true;
        branchLabel.text = gitState.branch;

        var parts = [];
        var SYM = {
            modified: "◆", untracked: "◇", staged: "+", deleted: "✘",
            ahead: "⇡", behind: "⇣", diverged: "⇕", stashed: "⧗", clean: "✓"
        };

        if (gitState.staged    > 0) parts.push(SYM.staged    + gitState.staged);
        if (gitState.modified  > 0) parts.push(SYM.modified  + gitState.modified);
        if (gitState.untracked > 0) parts.push(SYM.untracked + gitState.untracked);
        if (gitState.deleted   > 0) parts.push(SYM.deleted   + gitState.deleted);
        if (gitState.stashed   > 0) parts.push(SYM.stashed   + gitState.stashed);

        if (gitState.ahead > 0 && gitState.behind > 0) {
            parts.push(SYM.diverged + gitState.ahead + gitState.behind);
        } else if (gitState.ahead  > 0) {
            parts.push(SYM.ahead + gitState.ahead);
        } else if (gitState.behind > 0) {
            parts.push(SYM.behind + gitState.behind);
        }

        if (parts.length === 0) parts.push(SYM.clean);

        iconsLabel.text = parts.join(" ");
        iconsLabel.color = (parts.length === 1 && parts[0] === SYM.clean)
            ? "#a6e3a1" : "#f9e2af";
    }
}
