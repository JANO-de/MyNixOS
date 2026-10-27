import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.suite

ShellRoot {
    AppWindow {
        id: win

        title: "Calendar"
        implicitWidth: 900
        implicitHeight: 760

        property string tab: "month" // month, week, day, year, events, sync
        property bool showMonthEvents: false
        property var viewDate: new Date()
        property string selected: iso(new Date())
        property string icsUrl: ""
        property bool syncing: false
        property bool creating: false

        // new event draft
        property string draftTitle: ""
        property string draftDate: iso(new Date())
        property bool draftAllDay: true
        property string draftStart: "09:00"
        property string draftEnd: "10:00"
        property string draftType: "Event"
        property string draftNotes: ""

        readonly property var types: ["Event", "Meeting", "Task", "Reminder", "Birthday", "Focus", "Out of office"]
        readonly property var templates: [
            { name: "Meeting", title: "Meeting", type: "Meeting", dur: 60 },
            { name: "Focus", title: "Focus time", type: "Focus", dur: 120 },
            { name: "Reminder", title: "Reminder", type: "Reminder", dur: 15 },
            { name: "Birthday", title: "Birthday", type: "Birthday", dur: 0 }
        ]

        function pad(n) { return (n < 10 ? "0" : "") + n; }
        function iso(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()); }
        function monthTitle() { return Qt.formatDate(viewDate, "MMMM yyyy"); }
        function daysInMonth(y, m) { return new Date(y, m + 1, 0).getDate(); }
        function firstWeekday(y, m) { return new Date(y, m, 1).getDay(); }

        function eventsFor(dayIso) {
            const out = [];
            for (const e of events.value)
                if (String(e.start).substring(0, 10) === dayIso)
                    out.push(e);
            return out;
        }
        function allEventsSorted() {
            return events.value.slice().sort((a, b) => String(a.start).localeCompare(String(b.start)));
        }
        function eventCountForMonth(y, m) {
            const mm = pad(m);
            let n = 0;
            for (const e of events.value)
                if (String(e.start).substring(0, 7) === (y + "-" + mm))
                    n++;
            return n;
        }
        function addEvent() {
            if (draftTitle.trim() === "")
                return;
            const ev = {
                uid: String(Date.now()),
                title: draftTitle.trim(),
                start: draftDate,
                startTime: draftAllDay ? "" : draftStart,
                end: draftDate,
                endTime: draftAllDay ? "" : draftEnd,
                allDay: draftAllDay,
                type: draftType,
                notes: draftNotes.trim()
            };
            events.value = events.value.concat([ev]);
            events.save();
            creating = false;
            draftTitle = "";
            draftNotes = "";
        }
        function delEvent(uid) {
            events.value = events.value.filter(e => e.uid !== uid);
            events.save();
        }
        function applyTemplate(t) {
            draftTitle = t.title;
            draftType = t.type;
            if (t.dur > 0) {
                draftAllDay = false;
                const s = new Date();
                const e = new Date(s.getTime() + t.dur * 60000);
                draftStart = pad(s.getHours()) + ":" + pad(s.getMinutes());
                draftEnd = pad(e.getHours()) + ":" + pad(e.getMinutes());
            } else {
                draftAllDay = true;
            }
        }

        function syncIcs() {
            if (icsUrl.trim() === "")
                return;
            syncing = true;
            fetchProc.command = ["curl", "-s", "-L", "-m", "20", icsUrl.trim()];
            fetchProc.running = false;
            fetchProc.running = true;
        }
        Process {
            id: fetchProc
            stdout: StdioCollector {
                onStreamFinished: {
                    win.parseIcs(text);
                    win.syncing = false;
                }
            }
        }
        function parseIcs(txt) {
            const lines = txt.replace(/\r\n[ \t]/g, "").split(/\r?\n/);
            let inEvent = false;
            let cur = {};
            const newEvents = [];
            for (const raw of lines) {
                const line = raw.trim();
                if (line === "BEGIN:VEVENT") { inEvent = true; cur = {}; continue; }
                if (line === "END:VEVENT") {
                    if (cur.summary && cur.dtstart) {
                        const d = icsDate(cur.dtstart);
                        if (d)
                            newEvents.push({ uid: cur.uid || ("ics-" + Date.now() + "-" + newEvents.length), title: cur.summary, start: d, startTime: "", end: d, endTime: "", allDay: true, type: "Event", notes: "" });
                    }
                    inEvent = false;
                    continue;
                }
                if (!inEvent)
                    continue;
                const idx = line.indexOf(":");
                if (idx < 0)
                    continue;
                const key = line.substring(0, idx).toUpperCase();
                const val = line.substring(idx + 1);
                if (key.startsWith("SUMMARY"))
                    cur.summary = val;
                else if (key.startsWith("DTSTART"))
                    cur.dtstart = val;
                else if (key.startsWith("UID"))
                    cur.uid = val;
            }
            const kept = events.value.filter(e => !String(e.uid).startsWith("ics-"));
            events.value = kept.concat(newEvents);
            events.save();
        }
        function icsDate(v) {
            const m = v.match(/^(\d{4})(\d{2})(\d{2})/);
            if (!m)
                return "";
            return m[1] + "-" + m[2] + "-" + m[3];
        }

        JsonStore { id: events; name: "calendar-events"; fallback: [] }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // header
            Row {
                width: parent.width
                spacing: 8
                Pill { label: "‹"; onClicked: win.viewDate = new Date(win.viewDate.getFullYear(), win.viewDate.getMonth() - 1, 1) }
                Text { width: parent.width - 260; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(win.viewDate, "MMMM yyyy"); color: AppTheme.text; font.pixelSize: 24; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                Pill { label: "Today"; onClicked: { win.viewDate = new Date(); win.selected = win.iso(new Date()); } }
                Pill { label: "+"; filled: true; onClicked: { win.draftDate = win.selected; win.creating = true; } }
                Pill { label: "›"; onClicked: win.viewDate = new Date(win.viewDate.getFullYear(), win.viewDate.getMonth() + 1, 1) }
            }

            // view tabs
            Row {
                width: parent.width
                spacing: 6
                Repeater {
                    model: ["Month", "Week", "Day", "Year", "Events", "Sync"]
                    Pill {
                        required property string modelData
                        label: modelData
                        on: win.tab.toLowerCase() === modelData.toLowerCase()
                        onClicked: win.tab = modelData.toLowerCase()
                    }
                }
            }

            // Month view
            Column {
                visible: win.tab === "month"
                width: parent.width
                spacing: 6
                Grid {
                    columns: 7
                    spacing: 4
                    width: parent.width
                    Repeater {
                        model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                        Text {
                            required property string modelData
                            width: (parent.width - 24) / 7
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: AppTheme.dim
                            font.pixelSize: 12
                        }
                    }
                }
                Flickable {
                    width: parent.width
                    height: 300
                    contentWidth: width
                    contentHeight: grid.implicitHeight
                    clip: true
                    Grid {
                        id: grid
                        columns: 7
                        spacing: 4
                        width: parent.width
                        Repeater {
                            model: 42
                            Rectangle {
                                required property int index
                                readonly property int yr: win.viewDate.getFullYear()
                                readonly property int mo: win.viewDate.getMonth()
                                readonly property int first: win.firstWeekday(yr, mo)
                                readonly property int dim: win.daysInMonth(yr, mo)
                                readonly property int dayNum: index - first + 1
                                readonly property bool inMonth: dayNum > 0 && dayNum <= dim
                                readonly property string dayIso: inMonth ? (yr + "-" + win.pad(mo + 1) + "-" + win.pad(dayNum)) : ""
                                readonly property bool isToday: dayIso === win.iso(new Date())
                                readonly property bool isSelected: dayIso === win.selected
                                readonly property int evCount: inMonth ? win.eventsFor(dayIso).length : 0
                                width: (grid.width - 24) / 7
                                height: width
                                radius: 10
                                color: isSelected ? AppTheme.accent : (isToday ? AppTheme.accentSoft : (inMonth ? AppTheme.card : "transparent"))
                                Text {
                                    anchors.top: parent.top
                                    anchors.topMargin: 4
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: inMonth ? dayNum : ""
                                    color: isSelected ? AppTheme.accentInk : AppTheme.text
                                    font.pixelSize: 14
                                }
                                Text {
                                    visible: evCount > 0
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 4
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: evCount
                                    color: isSelected ? AppTheme.accentInk : AppTheme.accent
                                    font.pixelSize: 11
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: if (inMonth) win.selected = dayIso
                                }
                            }
                        }
                    }
                }
                Pill { label: win.showMonthEvents ? "Hide events" : "Show events"; onClicked: win.showMonthEvents = !win.showMonthEvents }
                Text { visible: win.showMonthEvents; width: parent.width; text: "Events on " + win.selected; color: AppTheme.text; font.pixelSize: 16; font.weight: Font.DemiBold }
                ListView {
                    visible: win.showMonthEvents
                    width: parent.width
                    height: win.showMonthEvents ? 110 : 0
                    clip: true
                    spacing: 4
                    model: win.eventsFor(win.selected)
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: 36
                        radius: 14
                        color: AppTheme.card
                        Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: (modelData.startTime ? modelData.startTime + "  " : "") + modelData.title; color: AppTheme.text; font.pixelSize: 14; width: parent.width - 40; elide: Text.ElideRight }
                        Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: "✕"; color: AppTheme.dim; font.pixelSize: 12
                            MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: win.delEvent(modelData.uid) } }
                    }
                }
            }

            // Week view
            Column {
                visible: win.tab === "week"
                width: parent.width
                spacing: 6
                Text { width: parent.width; text: "Week of " + win.iso(new Date(win.viewDate.getTime() - win.viewDate.getDay() * 86400000)); color: AppTheme.dim; font.pixelSize: 13 }
                Row {
                    width: parent.width
                    spacing: 4
                    Repeater {
                        model: 7
                        Column {
                            required property int index
                            readonly property var dayD: new Date(win.viewDate.getFullYear(), win.viewDate.getMonth(), win.viewDate.getDate() - win.viewDate.getDay() + index)
                            readonly property string dayIso: win.iso(dayD)
                            width: (parent.width - 24) / 7
                            spacing: 4
                            Rectangle { width: parent.width; height: 1; color: AppTheme.line }
                            Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(dayD, "ddd d"); color: AppTheme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Repeater {
                                model: win.eventsFor(dayIso)
                                Rectangle {
                                    required property var modelData
                                    width: parent.width
                                    height: 28
                                    radius: 8
                                    color: AppTheme.accentSoft
                                    border.width: 1
                                    border.color: AppTheme.line
                                    Text { x: 4; anchors.verticalCenter: parent.verticalCenter; text: modelData.title; color: AppTheme.text; font.pixelSize: 11; width: parent.width - 8; elide: Text.ElideRight }
                                }
                            }
                        }
                    }
                }
            }

            // Day view
            Column {
                visible: win.tab === "day"
                width: parent.width
                spacing: 8
                Text { width: parent.width; text: Qt.formatDate(new Date(win.selected), "dddd, d MMMM yyyy"); color: AppTheme.text; font.pixelSize: 20; font.weight: Font.DemiBold }
                Flickable {
                    width: parent.width
                    height: 420
                    contentWidth: width
                    contentHeight: dayCol.implicitHeight
                    clip: true
                    Column {
                        id: dayCol
                        width: parent.width
                        spacing: 2
                        // all-day events
                        Repeater {
                            model: win.eventsFor(win.selected).filter(e => e.allDay)
                            Rectangle {
                                required property var modelData
                                width: dayCol.width
                                height: 40
                                radius: 12
                                color: AppTheme.accentSoft
                                border.width: 1
                                border.color: AppTheme.line
                                Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.title + (modelData.type ? "  ·  " + modelData.type : ""); color: AppTheme.text; font.pixelSize: 14; width: parent.width - 40; elide: Text.ElideRight }
                                Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: "✕"; color: AppTheme.dim; font.pixelSize: 12
                                    MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: win.delEvent(modelData.uid) } }
                            }
                        }
                        Repeater {
                            model: 24
                            Column {
                                required property int index
                                width: dayCol.width
                                spacing: 2
                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: AppTheme.line
                                }
                                Row {
                                    width: parent.width
                                    spacing: 8
                                    Text {
                                        width: 52
                                        text: win.pad(index) + ":00"
                                        color: AppTheme.dim
                                        font.pixelSize: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Column {
                                        width: parent.width - 60
                                        spacing: 2
                                        Repeater {
                                            model: win.eventsFor(win.selected).filter(e => !e.allDay && parseInt((e.startTime || "0:0").split(":")[0]) === index)
                                            Rectangle {
                                                required property var modelData
                                                width: parent.width
                                                height: 34
                                                radius: 10
                                                color: AppTheme.card
                                                border.width: 1
                                                border.color: AppTheme.line
                                                Text { x: 8; anchors.verticalCenter: parent.verticalCenter; text: (modelData.startTime || "") + "  " + modelData.title; color: AppTheme.text; font.pixelSize: 13; width: parent.width - 30; elide: Text.ElideRight }
                                                Text { anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: "✕"; color: AppTheme.dim; font.pixelSize: 12
                                                    MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: win.delEvent(modelData.uid) } }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Pill { label: "Add event"; filled: true; onClicked: { win.draftDate = win.selected; win.creating = true; } }
            }

            // Year view
            Column {
                visible: win.tab === "year"
                width: parent.width
                spacing: 8
                Text { width: parent.width; text: win.viewDate.getFullYear(); color: AppTheme.text; font.pixelSize: 24; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter }
                Flickable {
                    width: parent.width
                    height: 420
                    contentWidth: width
                    contentHeight: yearGrid.implicitHeight
                    clip: true
                    Grid {
                        id: yearGrid
                        columns: 3
                        spacing: 12
                        width: parent.width
                        Repeater {
                            model: 12
                            Rectangle {
                                required property int index
                                width: (yearGrid.width - 24) / 3
                                height: 150
                                radius: 16
                                color: AppTheme.card
                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 4
                                    Text { width: parent.width; text: Qt.formatDate(new Date(win.viewDate.getFullYear(), index, 1), "MMM"); color: AppTheme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                                    Text {
                                        width: parent.width
                                        text: win.eventCountForMonth(win.viewDate.getFullYear(), index + 1) + " events"
                                        color: AppTheme.dim
                                        font.pixelSize: 11
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Events tab
            Column {
                visible: win.tab === "events"
                width: parent.width
                spacing: 8
                ListView {
                    width: parent.width
                    height: 420
                    clip: true
                    spacing: 4
                    model: win.allEventsSorted()
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: 44
                        radius: 16
                        color: AppTheme.card
                        Text { x: 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.start + (modelData.startTime ? " " + modelData.startTime : "") + "  " + modelData.title; color: AppTheme.text; font.pixelSize: 14; width: parent.width - 40; elide: Text.ElideRight }
                        Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: "✕"; color: AppTheme.dim; font.pixelSize: 12
                            MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: win.delEvent(modelData.uid) } }
                    }
                }
                Pill { label: "Add event"; filled: true; onClicked: { win.draftDate = win.selected; win.creating = true; } }
            }

            // Sync tab
            Column {
                visible: win.tab === "sync"
                width: parent.width
                spacing: 8
                Text { width: parent.width; text: "ICS sync"; color: AppTheme.text; font.pixelSize: 16; font.weight: Font.DemiBold }
                Row {
                    width: parent.width
                    spacing: 8
                    Field { id: icsField; width: parent.width - 140; placeholder: "https://.../calendar.ics" }
                    Pill { label: win.syncing ? "..." : "Sync"; filled: true; onClicked: { win.icsUrl = icsField.text; win.syncIcs(); } }
                }
                Text { width: parent.width; text: "Paste an ICS URL and tap Sync. Events are merged (existing manual events kept)."; color: AppTheme.dim; font.pixelSize: 12; wrapMode: Text.WordWrap }
            }
        }

        // Create event dialog
        Rectangle {
            visible: win.creating
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.5)
            MouseArea { anchors.fill: parent; onClicked: win.creating = false }
            Rectangle {
                width: Math.min(parent.width - 40, 520)
                height: 520
                anchors.centerIn: parent
                radius: 28
                color: AppTheme.card
                Column {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12
                    Text { width: parent.width; text: "New event"; color: AppTheme.text; font.pixelSize: 22; font.weight: Font.DemiBold }
                    Field { id: titleField; width: parent.width; placeholder: "Title"; onTextChanged: win.draftTitle = text }
                    Text { text: "Type"; color: AppTheme.dim; font.pixelSize: 13 }
                    Row {
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: win.types
                            Pill {
                                required property string modelData
                                label: modelData
                                on: win.draftType === modelData
                                onClicked: win.draftType = modelData
                            }
                        }
                    }
                    Text { text: "Templates"; color: AppTheme.dim; font.pixelSize: 13 }
                    Row {
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: win.templates
                            Pill {
                                required property var modelData
                                label: modelData.name
                                onClicked: win.applyTemplate(modelData)
                            }
                        }
                    }
                    Field { id: dateField; width: parent.width; placeholder: "Date YYYY-MM-DD"; text: win.draftDate; onTextChanged: win.draftDate = text }
                    Row {
                        spacing: 8
                        Pill { label: "All day"; on: win.draftAllDay; onClicked: win.draftAllDay = !win.draftAllDay }
                        Field { id: startField; width: 120; placeholder: "Start HH:MM"; text: win.draftStart; onTextChanged: win.draftStart = text }
                        Field { id: endField; width: 120; placeholder: "End HH:MM"; text: win.draftEnd; onTextChanged: win.draftEnd = text }
                    }
                    Field { id: notesField; width: parent.width; placeholder: "Notes"; onTextChanged: win.draftNotes = text }
                    Row {
                        spacing: 8
                        Pill { label: "Cancel"; onClicked: win.creating = false }
                        Pill { label: "Save"; filled: true; onClicked: win.addEvent() }
                    }
                }
            }
        }
    }
}
