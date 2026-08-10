import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Popup {
    id: root

    required property var desktop

    // If set to an existing "On My Computer" / iCalendar-file calendar that
    // Thunderbird already has configured (File > New Calendar > On My
    // Computer, or "iCalendar (ICS) File"), new events are appended
    // straight into that file instead of being opened as a one-off import.
    // Thunderbird picks up the change on its own refresh interval - no
    // import wizard. Leave empty to fall back to writing a standalone
    // .ics and opening it via xdg-open (which does trigger the wizard).
    property string calendarFilePath: ""

    modal: true
    dim: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    width: 260
    padding: 12

    // Selection/hover colors driven by the stylix theme, same alpha levels
    // used in the file manager (FileItem.qml).
    readonly property color selectedFill: Qt.rgba(root.desktop.base0E.r, root.desktop.base0E.g, root.desktop.base0E.b, 0.4)
    readonly property color selectedBorder: Qt.rgba(root.desktop.base0E.r, root.desktop.base0E.g, root.desktop.base0E.b, 0.6)
    readonly property color todayBorder: Qt.rgba(root.desktop.base0E.r, root.desktop.base0E.g, root.desktop.base0E.b, 0.6)
    readonly property color hoverFill: Qt.rgba(root.desktop.base03.r, root.desktop.base03.g, root.desktop.base03.b, 0.25)

    property date today: new Date()
    property date selectedDate: new Date()
    property int viewYear: selectedDate.getFullYear()
    property int viewMonth: selectedDate.getMonth()   // 0-indexed
    property var calendarCells: []

    property string statusText: ""
    property bool statusIsError: false

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var weekdayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    // ---- helpers ----------------------------------------------------
    function pad2(n) { return n < 10 ? "0" + n : "" + n; }

    function toIso(d) {
        return d.getFullYear() + "-" + pad2(d.getMonth() + 1) + "-" + pad2(d.getDate());
    }

    // Returns a Date for a valid "YYYY-MM-DD" string, or null if invalid
    // (including calendar-invalid dates like 2026-02-30).
    function parseIso(s) {
        var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s.trim());
        if (!m) return null;
        var y = parseInt(m[1], 10), mo = parseInt(m[2], 10), da = parseInt(m[3], 10);
        var d = new Date(y, mo - 1, da);
        if (d.getFullYear() !== y || d.getMonth() !== mo - 1 || d.getDate() !== da) return null;
        return d;
    }

    // Returns {h, m} for a valid "HH:MM" (24h) string, or null if invalid.
    function parseTime(s) {
        var m = /^([01]\d|2[0-3]):([0-5]\d)$/.exec(s.trim());
        if (!m) return null;
        return { h: parseInt(m[1], 10), m: parseInt(m[2], 10) };
    }

    // Always 6 full weeks (42 cells) so the popup's height never changes
    // between months.
    function rebuildGrid() {
        var first = new Date(viewYear, viewMonth, 1);
        var startWeekday = (first.getDay() + 6) % 7; // Mon=0 .. Sun=6
        var daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
        var cells = [];
        for (var i = 0; i < startWeekday; i++) cells.push(null);
        for (var d = 1; d <= daysInMonth; d++) cells.push(d);
        while (cells.length < 42) cells.push(null);
        calendarCells = cells;
    }

    function isSelected(day) {
        return day !== null
            && selectedDate.getFullYear() === viewYear
            && selectedDate.getMonth() === viewMonth
            && selectedDate.getDate() === day;
    }

    function isToday(day) {
        return day !== null
            && today.getFullYear() === viewYear
            && today.getMonth() === viewMonth
            && today.getDate() === day;
    }

    function selectDay(day) {
        if (day === null) return;
        selectedDate = new Date(viewYear, viewMonth, day);
        dateField.text = toIso(selectedDate);
    }

    function goToPrevMonth() {
        var m = viewMonth - 1, y = viewYear;
        if (m < 0) { m = 11; y -= 1; }
        viewMonth = m; viewYear = y;
        rebuildGrid();
    }

    function goToNextMonth() {
        var m = viewMonth + 1, y = viewYear;
        if (m > 11) { m = 0; y += 1; }
        viewMonth = m; viewYear = y;
        rebuildGrid();
    }

    // RFC5545 text escaping for SUMMARY/DESCRIPTION fields.
    function icsEscape(s) {
        return s
            .replace(/\\/g, "\\\\")
            .replace(/;/g, "\\;")
            .replace(/,/g, "\\,")
            .replace(/\r?\n/g, "\\n");
    }

    function icsDateStamp() {
        var d = new Date();
        return d.getUTCFullYear() + pad2(d.getUTCMonth() + 1) + pad2(d.getUTCDate())
            + "T" + pad2(d.getUTCHours()) + pad2(d.getUTCMinutes()) + pad2(d.getUTCSeconds()) + "Z";
    }

    function icsDateOnly(d) {
        return d.getFullYear() + pad2(d.getMonth() + 1) + pad2(d.getDate());
    }

    // Floating (no "Z") local date-time, e.g. 20260815T080000
    function icsDateTime(d) {
        return icsDateOnly(d) + "T" + pad2(d.getHours()) + pad2(d.getMinutes()) + "00";
    }

    function resetForm() {
        titleField.text = "";
        noteField.text = "";
        timeField.text = "08:00";
        selectedDate = new Date();
        viewYear = selectedDate.getFullYear();
        viewMonth = selectedDate.getMonth();
        rebuildGrid();
        dateField.text = toIso(selectedDate);
    }

    function createEvent() {
        var title = titleField.text.trim();
        if (title === "") {
            statusText = "Title is required.";
            statusIsError = true;
            return;
        }
        var time = parseTime(timeField.text);
        if (!time) {
            statusText = "Invalid time, use HH:MM.";
            statusIsError = true;
            return;
        }

        var start = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate(), time.h, time.m);
        var end = new Date(start.getTime() + 60 * 60 * 1000); // 1 hour default duration
        var uid = Date.now() + "-" + Math.floor(Math.random() * 100000) + "@quickshell.local";

        var veventLines = [
            "BEGIN:VEVENT",
            "UID:" + uid,
            "DTSTAMP:" + icsDateStamp(),
            "DTSTART:" + icsDateTime(start),
            "DTEND:" + icsDateTime(end),
            "SUMMARY:" + icsEscape(title)
        ];
        if (noteField.text.trim() !== "") {
            veventLines.push("DESCRIPTION:" + icsEscape(noteField.text.trim()));
        }
        veventLines.push("END:VEVENT");

        if (root.calendarFilePath !== "") {
            appendToCalendarFile(veventLines);
        } else {
            createStandaloneFile(veventLines, start);
        }
    }

    // Appends directly into an existing calendar file Thunderbird is
    // already subscribed to - no import wizard.
    FileView {
        id: calendarFileRW
        blockLoading: true
        blockWrites: true
    }

    function appendToCalendarFile(veventLines) {
        calendarFileRW.path = root.calendarFilePath;
        var current = "";
        try {
            current = calendarFileRW.text();
        } catch (e) {
            current = "";
        }
        var veventBlock = veventLines.join("\r\n");
        var newContent;
        if (current && current.indexOf("BEGIN:VCALENDAR") !== -1 && current.indexOf("END:VCALENDAR") !== -1) {
            newContent = current.replace(/END:VCALENDAR\s*$/, veventBlock + "\r\nEND:VCALENDAR\r\n");
        } else {
            newContent = "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//quickshell//calendar-popup//EN\r\nCALSCALE:GREGORIAN\r\n"
                + veventBlock + "\r\nEND:VCALENDAR\r\n";
        }
        calendarFileRW.setText(newContent);
        statusText = "Event added to calendar.";
        statusIsError = false;
        resetForm();
    }

    // Fallback: standalone .ics opened via xdg-open (triggers Thunderbird's
    // import wizard, since it isn't tied to a subscribed calendar).
    FileView {
        id: eventFile
        blockWrites: true
    }

    Process {
        id: mkdirProc
        running: false
    }

    Process {
        id: openProc
        running: false
    }

    function createStandaloneFile(veventLines, start) {
        var lines = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//quickshell//calendar-popup//EN",
            "CALSCALE:GREGORIAN"
        ].concat(veventLines).concat(["END:VCALENDAR"]);

        var fileName = "event-" + icsDateOnly(start) + "-" + Date.now() + ".ics";
        eventFile.path = Quickshell.dataPath("calendar-events/" + fileName);
        mkdirProc.command = ["sh", "-c", "mkdir -p " + Quickshell.dataPath("calendar-events")];
        mkdirProc.exited.connect(function writeOnce(exitCode) {
            mkdirProc.exited.disconnect(writeOnce);
            eventFile.setText(lines.join("\r\n") + "\r\n");
            openProc.command = ["xdg-open", eventFile.path];
            openProc.running = true;
            statusText = "Event created and opened.";
            statusIsError = false;
            resetForm();
        });
        mkdirProc.running = true;
    }

    // ---- flat styling helpers: buttons/fields match the popup background
    component FlatButton: Button {
        font.pixelSize: 13
        background: Rectangle {
            radius: 4
            color: root.desktop.base01
        }
        contentItem: Label {
            text: parent.text
            color: root.desktop.base04
            font.pixelSize: parent.font.pixelSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    component FlatTextField: TextField {
        color: root.desktop.base04
        placeholderTextColor: Qt.rgba(root.desktop.base04.r, root.desktop.base04.g, root.desktop.base04.b, 0.5)
        selectByMouse: true
        leftPadding: 8
        rightPadding: 8
        topPadding: 6
        bottomPadding: 6
        background: Rectangle {
            radius: 4
            color: root.desktop.base01
        }
    }

    background: Rectangle {
        color: root.desktop.base01
        border.color: Qt.rgba(root.desktop.base04.r, root.desktop.base04.g, root.desktop.base04.b, 0.3)
        border.width: 1
        radius: 6
    }

    onOpened: {
        today = new Date();
        viewYear = selectedDate.getFullYear();
        viewMonth = selectedDate.getMonth();
        rebuildGrid();
        dateField.text = toIso(selectedDate);
        statusText = "";
        titleField.forceActiveFocus();
    }

    contentItem: ColumnLayout {
        spacing: 8

        // ---- month header ----
        RowLayout {
            Layout.fillWidth: true
            FlatButton {
                text: "◉"
                implicitHeight: 28
                onClicked: {
                    root.today = new Date();
                    root.viewYear = root.today.getFullYear();
                    root.viewMonth = root.today.getMonth();
                    root.rebuildGrid();
                }
            }
            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                color: root.desktop.base04
                font.pixelSize: 14
                font.bold: true
                text: root.monthNames[root.viewMonth] + " " + root.viewYear
            }
            FlatButton {
                text: "◀"
                implicitWidth: 28
                implicitHeight: 28
                onClicked: root.goToPrevMonth()
            }
            FlatButton {
                text: "▶"
                implicitWidth: 28
                implicitHeight: 28
                onClicked: root.goToNextMonth()
            }
        }

        // ---- weekday header ----
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 2
            rowSpacing: 2
            Repeater {
                model: root.weekdayNames
                delegate: Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    color: root.desktop.base04
                    font.pixelSize: 11
                    text: modelData
                }
            }
        }

        // ---- day grid (always 6 rows so height never jumps) ----
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 2
            rowSpacing: 2
            Repeater {
                model: root.calendarCells
                delegate: Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    Rectangle {
                        id: dayCell
                        anchors.fill: parent
                        visible: modelData !== null
                        property bool dayHovered: false
                        radius: 4
                        color: root.isSelected(modelData)
                            ? root.selectedFill
                            : (dayHovered ? root.hoverFill : "transparent")
                        border.color: root.isToday(modelData) ? root.todayBorder : "transparent"
                        border.width: root.isToday(modelData) ? 1 : 0
                        Label {
                            anchors.centerIn: parent
                            text: modelData !== null ? modelData : ""
                            font.pixelSize: 12
                            font.bold: root.isToday(modelData)
                            color: root.desktop.base04
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: modelData !== null ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onEntered: dayCell.dayHovered = true
                            onExited: dayCell.dayHovered = false
                            onClicked: root.selectDay(modelData)
                        }
                    }
                }
            }
        }

        // ---- ISO 8601 date + time ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            FlatTextField {
                id: dateField
                Layout.fillWidth: true
                placeholderText: "YYYY-MM-DD"
                font.pixelSize: 13
                onEditingFinished: {
                    var d = root.parseIso(text);
                    if (d) {
                        root.selectedDate = d;
                        root.viewYear = d.getFullYear();
                        root.viewMonth = d.getMonth();
                        root.rebuildGrid();
                        root.statusText = "";
                    } else {
                        root.statusText = "Invalid date, use YYYY-MM-DD.";
                        root.statusIsError = true;
                        text = root.toIso(root.selectedDate);
                    }
                }
            }
            FlatTextField {
                id: timeField
                Layout.preferredWidth: 72
                text: "08:00"
                placeholderText: "HH:MM"
                font.pixelSize: 13
                onEditingFinished: {
                    var t = root.parseTime(text);
                    if (!t) {
                        root.statusText = "Invalid time, use HH:MM.";
                        root.statusIsError = true;
                        text = "08:00";
                    } else {
                        root.statusText = "";
                    }
                }
            }
        }

        // ---- title / note ----
        TextField {
            id: titleField
            Layout.fillWidth: true
            placeholderText: "Title"
            font.pixelSize: 13
            color: root.desktop.base04
            placeholderTextColor: Qt.rgba(root.desktop.base04.r, root.desktop.base04.g, root.desktop.base04.b, 0.5)
            selectByMouse: true
            leftPadding: 8
            rightPadding: 8
            topPadding: 6
            bottomPadding: 6
            background: Rectangle {
                color: "transparent"
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: root.desktop.base04
                }
            }
        }

        TextArea {
            id: noteField
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            placeholderText: "Note"
            wrapMode: TextArea.Wrap
            font.pixelSize: 13
            color: root.desktop.base04
            placeholderTextColor: Qt.rgba(root.desktop.base04.r, root.desktop.base04.g, root.desktop.base04.b, 0.5)
            selectByMouse: true
            leftPadding: 8
            rightPadding: 8
            topPadding: 6
            bottomPadding: 6
            background: Rectangle {
                radius: 4
                color: root.desktop.base01
            }
        }

        // Fixed height reserved always, so showing/hiding the status
        // message never shifts the popup's size.
        Label {
            Layout.fillWidth: true
            Layout.preferredHeight: 16
            text: root.statusText
            elide: Text.ElideRight
            font.pixelSize: 11
            color: root.statusIsError ? "#e06c75" : root.desktop.base04
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            FlatButton {
                text: "⌵"
                implicitWidth: 28
                implicitHeight: 28
                onClicked: root.close()
            }
            FlatButton {
                text: "Create Event"
                Layout.fillWidth: true
                onClicked: root.createEvent()
            }
        }
    }
}
