import QtQuick 2.15
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    property string fontFamily: "Iosevka NFM"
    property color bgColor: "#1a1a2e"
    property color selColor: "#008080"
    property color fgColor: "#f0f0f0"
    property color commentColor: "#4a4a4a"

    readonly property string stylixPath: Quickshell.env("HOME") + "/.config/stylix/palette.json"

    FileView {
        id: stylixFile
        path: root.stylixPath
        onTextChanged: {
            var raw = text().trim()
            if (raw.length === 0) return
            try {
                var palette = JSON.parse(raw)
                var colors = palette.palette || palette
                function toColor(hex) {
                    if (!hex) return null
                    hex = hex.toString().trim()
                    if (hex.charAt(0) !== "#") hex = "#" + hex
                    return hex
                }
                var c00 = toColor(colors.base00)
                var c03 = toColor(colors.base03)
                var c05 = toColor(colors.base05)
                var c0e = toColor(colors.base0E)
                if (c00) root.bgColor = c00
                if (c03) root.commentColor = c03
                if (c05) root.fgColor = c05
                if (c0e) root.selColor = c0e
            } catch (e) {
                console.warn("Failed to parse stylix palette:", e)
            }
        }
    }
}
