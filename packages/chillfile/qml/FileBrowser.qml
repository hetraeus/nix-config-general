import QtQuick
import Quickshell
import Quickshell.Io

// Owns the current directory, navigation history, and the (possibly
// filtered) directory listing. Pure logic + background processes only —
// no visual elements and no references to any UI item. Consumers bind to
// filteredModel/currentPath/etc. and call navigateTo()/goUp()/
// historyForward()/goToParent().
QtObject {
    id: root

    property string fileiconPath: Quickshell.env("FILEICON_PATH") || "/usr/bin/fileicon"

    property string currentPath: {
        var start = Quickshell.env("QS_START_PATH");
        return start || (Quickshell.env("HOME") + "/my/proj");
    }

    property string initialPath: ""
    property var navStack: [currentPath]
    property var forwardStack: []

    property string filterText: ""
    property bool recursiveSearch: false
    property var currentEntries: []
    property string lastFocusedPath: ""

    property bool pendingFilterClear: false
    property bool suppressTextFilter: false
    property bool ignoreNextFilterChange: false

    property int listingGeneration: 0
    property int lastLsGen: 0
    property int lastFindGen: 0

    // Emitted after currentPath has changed as a result of navigateTo(),
    // goUp() or historyForward(). UI-side cosmetics (clearing the search
    // field, refocusing the grid) hook off this instead of living inline
    // in the navigation functions.
    signal navigated()

    // Emitted whenever filteredModel has been rebuilt. UI-side selection
    // (which row should end up focused) hooks off this.
    signal filterApplied()

    property var filteredModel: ListModel {}

    property var iconPaths: ({})
    property string iconLookupPath: ""

    property var lsProc: Process {
        running: false
        command: ["ls", "-1", "-F", root.currentPath]

        stdout: StdioCollector {
            onStreamFinished: root.parseLsOutput(text)
        }
    }

    property var findProc: Process {
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.parseFindOutput(text)
        }
    }

    property var iconProc: Process {
        running: false
        command: [root.fileiconPath]

        stdout: StdioCollector {
            onStreamFinished: root.parseIconOutput(text)
        }
    }

    function basename(path) {
        var parts = path.split('/');
        return parts[parts.length - 1];
    }

    function navigateTo(path) {
        root.forwardStack = [];
        var newStack = root.navStack.slice();
        newStack.push(path);
        root.navStack = newStack;
        root.pendingFilterClear = true;
        root.currentPath = path;
        root.navigated();
    }

    function goUp() {
        if (root.navStack.length > 1) {
            var current = root.navStack[root.navStack.length - 1];
            root.lastFocusedPath = current;   // select this dir when we land back in parent

            var newForward = root.forwardStack.slice();
            newForward.push(current);
            root.forwardStack = newForward;

            var newStack = root.navStack.slice();
            newStack.pop();
            root.navStack = newStack;
            root.pendingFilterClear = true;
            root.currentPath = newStack[newStack.length - 1];
            root.navigated();
        }
    }

    function historyForward() {
        if (root.forwardStack.length > 0) {
            var newForward = root.forwardStack.slice();
            var next = newForward.pop();
            root.forwardStack = newForward;

            root.lastFocusedPath = next;   // select this dir when we later go back

            var newStack = root.navStack.slice();
            newStack.push(next);
            root.navStack = newStack;
            root.pendingFilterClear = true;
            root.currentPath = next;
            root.navigated();
        }
    }

    function goToParent() {
        var path = root.currentPath;
        var parts = path.split('/');
        if (parts.length > 1) {
            parts.pop();
            var parentPath = parts.join('/');
            if (parentPath === "") parentPath = "/";
            if (parentPath !== root.currentPath) {
                root.lastFocusedPath = root.currentPath;   // select current dir in parent
                root.navigateTo(parentPath);
            }
        }
    }

    function parseLsOutput(output) {
        if (root.lastLsGen !== root.listingGeneration) return;

        var lines = output.trim().split("\n");
        var dirs = [];
        var files = [];
        var i;

        for (i = 0; i < lines.length; i++) {
            var line = lines[i];
            if (!line || line.startsWith(".")) continue;

            var isDir = line.endsWith("/");
            var rawName = isDir ? line.slice(0, -1) : line;
            var name = rawName.replace(/[*@=\|>]$/, "");

            var entry = {
                name: name,
                path: root.currentPath + "/" + name,
                isDir: isDir
            };

            if (isDir) dirs.push(entry);
            else files.push(entry);
        }

        root.currentEntries = dirs.concat(files);

        var hadPending = root.pendingFilterClear;
        if (hadPending) {
            root.ignoreNextFilterChange = true;
            root.filterText = "";
            root.pendingFilterClear = false;
        }

        if (!hadPending || root.filterText === "") {
            runIconLookup();
        }
    }

    function parseFindOutput(output) {
        if (root.lastFindGen !== root.listingGeneration) return;

        var lines = output.trim().split("\n");
        var entries = [];
        var i;

        for (i = 0; i < lines.length && entries.length < 100; i++) {
            var line = lines[i];
            if (!line) continue;

            var parts = line.split("\t");
            if (parts.length < 2) continue;

            var type = parts[0];
            var path = parts[1];
            var name = basename(path);

            entries.push({
                name: name,
                path: path,
                isDir: type === "d"
            });
        }

        root.currentEntries = entries;
        runIconLookup();
    }

    function runIconLookup() {
        root.iconLookupPath = root.currentPath;
        if (root.currentEntries.length === 0) {
            root.iconPaths = {};
            applyFilter();
            return;
        }
        var args = [root.fileiconPath];
        for (var i = 0; i < root.currentEntries.length; i++) {
            args.push(root.currentEntries[i].path);
        }
        iconProc.command = args;
        iconProc.running = true;
    }

    function parseIconOutput(output) {
        if (root.iconLookupPath !== root.currentPath) return;
        root.iconPaths = {};
        var lines = output.trim().split("\n");
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];
            var tabIdx = line.indexOf("\t");
            if (tabIdx >= 0) {
                var path = line.substring(0, tabIdx);
                var iconPath = line.substring(tabIdx + 1);
                root.iconPaths[path] = iconPath;
            }
        }
        applyFilter();
    }

    function runListing() {
        root.listingGeneration++;
        if (root.pendingFilterClear) {
            lsProc.command = ["ls", "-1", "-F", root.currentPath];
            lsProc.running = true;
            root.lastLsGen = root.listingGeneration;
            return;
        }
        if (root.recursiveSearch && root.filterText.length >= 3) {
            var q = root.filterText;
            findProc.command = [
                "find", root.currentPath, "-maxdepth", "15",
                "-type", "f", "-iname", "*" + q + "*", "-exec", "printf", "f\t%s\n", "{}", "+",
                "-o",
                "-type", "d", "-iname", "*" + q + "*", "-exec", "printf", "d\t%s\n", "{}", "+"
            ];
            findProc.running = true;
            root.lastFindGen = root.listingGeneration;
        } else {
            lsProc.command = ["ls", "-1", "-F", root.currentPath];
            lsProc.running = true;
            root.lastLsGen = root.listingGeneration;
        }
    }

    function applyFilter() {
        var q = root.filterText.toLowerCase().trim();
        var queryParts = [];
        var parts = q.split(/\s+/);
        var i;
        for (i = 0; i < parts.length; i++) {
            if (parts[i].length > 0) queryParts.push(parts[i]);
        }

        filteredModel.clear();

        for (i = 0; i < root.currentEntries.length; i++) {
            var entry = root.currentEntries[i];
            var modelEntry = {
                name: entry.name,
                path: entry.path,
                isDir: entry.isDir,
                iconPath: root.iconPaths[entry.path] || ""
            };
            if (q === "") {
                filteredModel.append(modelEntry);
            } else {
                var name = entry.name.toLowerCase();
                var matches = true;
                for (var j = 0; j < queryParts.length; j++) {
                    if (name.indexOf(queryParts[j]) < 0) {
                        matches = false;
                        break;
                    }
                }
                if (matches) filteredModel.append(modelEntry);
            }
        }

        root.filterApplied();
    }

    onCurrentPathChanged: runListing()

    onFilterTextChanged: {
        if (root.ignoreNextFilterChange) {
            root.ignoreNextFilterChange = false;
            return;
        }
        if (root.pendingFilterClear) {
            return;
        }
        if (root.recursiveSearch && root.filterText.length >= 3) {
            var q = root.filterText;
            findProc.command = [
                "find", root.currentPath, "-maxdepth", "15",
                "-type", "f", "-iname", "*" + q + "*", "-exec", "printf", "f\t%s\n", "{}", "+",
                "-o",
                "-type", "d", "-iname", "*" + q + "*", "-exec", "printf", "d\t%s\n", "{}", "+"
            ];
            findProc.running = true;
            root.lastFindGen = root.listingGeneration;
        } else if (root.recursiveSearch && root.filterText.length < 3) {
            lsProc.command = ["ls", "-1", "-F", root.currentPath];
            lsProc.running = true;
            root.lastLsGen = root.listingGeneration;
        } else {
            applyFilter();
        }
    }

    onRecursiveSearchChanged: {
        if (root.pendingFilterClear) {
            return;
        }
        if (root.recursiveSearch && root.filterText.length >= 3) {
            var q = root.filterText;
            findProc.command = [
                "find", root.currentPath, "-maxdepth", "15",
                "-type", "f", "-iname", "*" + q + "*", "-exec", "printf", "f\t%s\n", "{}", "+",
                "-o",
                "-type", "d", "-iname", "*" + q + "*", "-exec", "printf", "d\t%s\n", "{}", "+"
            ];
            findProc.running = true;
            root.lastFindGen = root.listingGeneration;
        } else if (!root.recursiveSearch) {
            lsProc.command = ["ls", "-1", "-F", root.currentPath];
            lsProc.running = true;
            root.lastLsGen = root.listingGeneration;
        }
    }

    Component.onCompleted: {
        root.initialPath = root.currentPath;
        runListing();
    }
}
