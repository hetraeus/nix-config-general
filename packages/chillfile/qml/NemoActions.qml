import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property var actions: []
    property bool loaded: false

    function refresh() {
        discoverProc.running = true;
    }

    function getApplicableActions(selectedPaths, targetPath, isDir) {
        if (!root.loaded) return [];

        var selCount = selectedPaths.length;
        var result = [];

        for (var i = 0; i < root.actions.length; i++) {
            var act = root.actions[i];

            // ---- Selection count filter ----
            var sel = (act.selection || "any").toLowerCase();
            var selOk = false;
            if (sel === "s" || sel === "single") {
                selOk = (selCount === 1);
            } else if (sel === "m" || sel === "multiple") {
                selOk = (selCount > 1);
            } else if (sel === "notnone") {
                selOk = (selCount > 0);
            } else if (sel === "none") {
                selOk = (selCount === 0);
            } else {
                selOk = true; // any
            }

            if (!selOk) continue;

            if (selCount === 0) {
                result.push(act);
                continue;
            }

            var checkPaths = (sel === "s" || sel === "single") ? [targetPath] : selectedPaths;

            // ---- Extensions filter ----
            if (act.extensions && act.extensions !== "") {
                var exts = act.extensions.toLowerCase().split(/\s*,\s*/);
                var extMatch = true;
                for (var p = 0; p < checkPaths.length; p++) {
                    var parts = checkPaths[p].split('.');
                    var pathExt = parts.length > 1 ? parts.pop().toLowerCase() : "";
                    if (exts.indexOf(pathExt) < 0) {
                        extMatch = false;
                        break;
                    }
                }
                if (!extMatch) continue;
            }

            // If it's a directory and the action specifies extensions,
            // assume it's meant for files and skip it.
            if (isDir && act.extensions && act.extensions !== "") {
                continue;
            }

            result.push(act);
        }

        return result;
    }

    function buildExecCommand(execTemplate, selectedPaths, targetPath) {
        var cmd = execTemplate;

        // %F — full paths of selected file(s), shell-quoted
        if (cmd.indexOf("%F") >= 0) {
            var paths = selectedPaths.length > 0 ? selectedPaths : [targetPath];
            var quoted = paths.map(function(p) {
                return "'" + p.replace(/'/g, "'\\''") + "'";
            });
            cmd = cmd.replace(/%F/g, quoted.join(" "));
        }

        // %f — basename of target file
        if (cmd.indexOf("%f") >= 0) {
            var base = targetPath.split('/').pop();
            cmd = cmd.replace(/%f/g, base);
        }

        // %P — parent directory, shell-quoted
        if (cmd.indexOf("%P") >= 0) {
            var parts = targetPath.split('/');
            parts.pop();
            var parent = parts.join('/') || '/';
            cmd = cmd.replace(/%P/g, "'" + parent.replace(/'/g, "'\\''") + "'");
        }

        // %N — basename without extension
        if (cmd.indexOf("%N") >= 0) {
            var base = targetPath.split('/').pop();
            var dot = base.lastIndexOf('.');
            var name = dot > 0 ? base.substring(0, dot) : base;
            cmd = cmd.replace(/%N/g, name);
        }

        // %O — extension without dot
        if (cmd.indexOf("%O") >= 0) {
            var base = targetPath.split('/').pop();
            var dot = base.lastIndexOf('.');
            var ext = dot > 0 ? base.substring(dot + 1) : "";
            cmd = cmd.replace(/%O/g, ext);
        }

        // %U — file URI
        if (cmd.indexOf("%U") >= 0) {
            cmd = cmd.replace(/%U/g, "file://" + targetPath);
        }

        return cmd;
    }

    Process {
        id: discoverProc
        running: false
        command: ["sh", "-c",
            "for d in \"" + (Quickshell.env("HOME") || "") + "/.local/share/nemo/actions\" /usr/share/nemo/actions; do " +
            "  [ -d \"$d\" ] || continue; " +
            "  for f in \"$d\"/*.nemo_action; do " +
            "    [ -f \"$f\" ] || continue; " +
            "    awk '/^\\[Nemo Action\\]/ {s=1; next} /^\\[/ {s=0} s {print}' \"$f\" | while IFS='=' read -r k v; do " +
            "      k=$(echo \"$k\" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'); " +
            "      v=$(echo \"$v\" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'); " +
            "      printf '%s\\t%s\\n' \"$k\" \"$v\"; " +
            "    done; " +
            "    printf '---END---\\n'; " +
            "  done; " +
            "done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.parseActions(text);
            }
        }
    }

    function parseActions(text) {
        var lines = text.trim().split("\n");
        var newActions = [];
        var current = null;

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];
            if (line === "---END---") {
                if (current && current.name && current.exec) {
                    newActions.push(current);
                }
                current = null;
                continue;
            }

            if (!current) current = { name: "", exec: "", selection: "any", extensions: "", mimetypes: "", icon: "" };

            var tab = line.indexOf("\t");
            if (tab < 0) continue;
            var key = line.substring(0, tab).toLowerCase();
            var val = line.substring(tab + 1);

            switch (key) {
                case "name": current.name = val; break;
                case "exec": current.exec = val; break;
                case "selection": current.selection = val; break;
                case "extensions": current.extensions = val; break;
                case "mimetypes": current.mimetypes = val; break;
                case "icon": current.icon = val; break;
            }
        }

        root.actions = newActions;
        root.loaded = true;
    }

    Component.onCompleted: {
        refresh();
    }
}
