import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false

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
            // Nemo action files delimit extensions with ';' (like .desktop files),
            // e.g. "txt;doc;" or the common wildcard "any;". Trailing/empty tokens
            // from the trailing ';' are dropped.
            var rawExts = (act.extensions || "").toLowerCase().split(";")
                .map(function(e) { return e.trim(); })
                .filter(function(e) { return e.length > 0; });

            var isAny = rawExts.length === 0 || rawExts.indexOf("any") >= 0;
            var wantsDirs = rawExts.indexOf("dir") >= 0 || rawExts.indexOf("dirs") >= 0;
            var wantsNoDirs = rawExts.indexOf("nodirs") >= 0;

            if (isDir) {
                // Directories: only excluded if the action explicitly excludes them,
                // or if it lists concrete extensions (which only make sense for files)
                // without also allowing "any"/"dir(s)".
                if (wantsNoDirs) continue;
                if (!isAny && !wantsDirs) continue;
            } else if (!isAny) {
                var extMatch = true;
                for (var p = 0; p < checkPaths.length; p++) {
                    var parts = checkPaths[p].split('.');
                    var pathExt = parts.length > 1 ? parts.pop().toLowerCase() : "";
                    if (rawExts.indexOf(pathExt) < 0) {
                        extMatch = false;
                        break;
                    }
                }
                if (!extMatch) continue;
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
            "  echo \"[scan] checking $d\" >&2; " +
            "  [ -d \"$d\" ] || { echo \"[scan] $d does not exist\" >&2; continue; }; " +
            "  for f in \"$d\"/*.nemo_action; do " +
            "    [ -f \"$f\" ] || continue; " +
            "    echo \"[scan] found $f\" >&2; " +
            "    awk '/^\\[Nemo Action\\]/ {s=1; next} /^\\[/ {s=0} s {print}' \"$f\" | while IFS='=' read -r k v; do " +
            "      k=$(echo \"$k\" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'); " +
            "      v=$(echo \"$v\" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'); " +
            "      printf '%s\\t%s\\n' \"$k\" \"$v\"; " +
            "    done; " +
            "    printf -- '---END---\\n'; " +
            "  done; " +
            "done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("[NemoActions] stdout length:", text.length);
                console.log("[NemoActions] stdout raw:", JSON.stringify(text));
                root.parseActions(text);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.log("[NemoActions] stderr:", text);
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            console.log("[NemoActions] discoverProc exited, code:", exitCode);
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
        console.log("[NemoActions] parsed", newActions.length, "action(s):",
            newActions.map(function(a) { return a.name + " (ext=" + a.extensions + ", sel=" + a.selection + ")"; }).join(" | "));
    }

    Component.onCompleted: {
        console.log("[NemoActions] HOME:", Quickshell.env("HOME"));
        refresh();
    }
}
