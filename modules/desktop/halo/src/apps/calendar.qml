import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.suite

ShellRoot {
    SuiteWindow {
        id: win

        title: "Calendar"
        implicitWidth: 900
        implicitHeight: 780

        property string tab: "month" // month, week, day, year, events, sync
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
        readonly property var dayNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        function pad(n) { return (n < 10 ? "0" : "") + n; }
        function iso(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()); }
        function selDate() { return new Date(selected + "T12:00:00"); }
        function daysInMonth(y, m) { return new Date(y, m + 1, 0).getDate(); }
        function firstWeekday(y, m) { return (new Date(y, m, 1).getDay() + 6) % 7; }   // Monday first, like the home screen calendar widget
        function weekStart() {
            const d = new Date(viewDate.getFullYear(), viewDate.getMonth(), viewDate.getDate());
            d.setDate(d.getDate() - (d.getDay() + 6) % 7);
            return d;
        }
        function headTitle() {
            if (tab === "year")
                return String(viewDate.getFullYear());
            if (tab === "day")
                return Qt.formatDate(selDate(), "ddd d MMM yyyy");
            if (tab === "week") {
                const s = weekStart();
                return Qt.formatDate(s, "d MMM") + " – " + Qt.formatDate(new Date(s.getFullYear(), s.getMonth(), s.getDate() + 6), "d MMM yyyy");
            }
            return Qt.formatDate(viewDate, "MMMM yyyy");
        }
        function shift(dir) {
            const d = viewDate;
            if (tab === "week")
                viewDate = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 7 * dir);
            else if (tab === "day") {
                viewDate = new Date(d.getFullYear(), d.getMonth(), d.getDate() + dir);
                selected = iso(viewDate);
            } else if (tab === "year")
                viewDate = new Date(d.getFullYear() + dir, d.getMonth(), 1);
            else
                viewDate = new Date(d.getFullYear(), d.getMonth() + dir, 1);
        }
        function evSub(e, withDate) {
            return (withDate ? e.start + (e.startTime ? " " + e.startTime : "") + "  ·  " : (e.startTime ? e.startTime + (e.endTime ? "–" + e.endTime : "") + "  ·  " : "")) + (e.type || "Event");
        }

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
        function openCreate(dayIso) {
            draftDate = dayIso;
            draftAllDay = true;
            draftStart = "09:00";
            draftEnd = "10:00";
            draftType = "Event";
            draftTitle = "";
            draftNotes = "";
            titleField.text = "";
            dateField.text = dayIso;
            startField.text = "09:00";
            endField.text = "10:00";
            notesField.text = "";
            creating = true;
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
        }
        function delEvent(uid) {
            events.value = events.value.filter(e => e.uid !== uid);
            events.save();
        }
        function applyTemplate(t) {
            draftTitle = t.title;
            titleField.text = t.title;
            draftType = t.type;
            if (t.dur > 0) {
                draftAllDay = false;
                const s = new Date();
                const e = new Date(s.getTime() + t.dur * 60000);
                draftStart = pad(s.getHours()) + ":" + pad(s.getMinutes());
                draftEnd = pad(e.getHours()) + ":" + pad(e.getMinutes());
                startField.text = draftStart;
                endField.text = draftEnd;
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

        actions: [
            Pill { label: "Today"; onClicked: { win.viewDate = new Date(); win.selected = win.iso(new Date()); } },
            Pill { icon: "plus"; filled: true; onClicked: win.openCreate(win.selected) }
        ]

        // ---- header: previous / title / next, then the view switcher --------------------------
        Item {
            id: head
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            height: 44
            Pill { id: prevBtn; icon: "back"; anchors.left: parent.left; onClicked: win.shift(-1) }
            Pill { id: nextBtn; icon: "fwd"; anchors.right: parent.right; onClicked: win.shift(1) }
            Text {
                anchors.left: prevBtn.right
                anchors.right: nextBtn.left
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: win.headTitle()
                color: AppTheme.text
                font.pixelSize: 24
                font.weight: Font.DemiBold
            }
        }
        Item {
            id: tabsRow
            anchors.top: head.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: 44
            Seg {
                anchors.horizontalCenter: parent.horizontalCenter
                model: [{ label: "Month", value: "month" }, { label: "Week", value: "week" }, { label: "Day", value: "day" },
                        { label: "Year", value: "year" }, { label: "Events", value: "events" }, { label: "Sync", value: "sync" }]
                current: win.tab
                onPicked: value => win.tab = value
            }
        }

        Item {
            id: pane
            anchors.top: tabsRow.bottom
            anchors.topMargin: 12
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 16

            // ---- Month ------------------------------------------------------------------
            Item {
                id: monthView
                visible: win.tab === "month"
                anchors.fill: parent
                readonly property real cellH: Math.max(40, Math.min(64, (height - 22 - 190) / 6))

                Row {
                    id: wk
                    width: parent.width
                    height: 22
                    Repeater {
                        model: win.dayNames
                        Item {
                            required property string modelData
                            width: wk.width / 7
                            height: 22
                            Text { anchors.centerIn: parent; text: modelData; color: AppTheme.dim; font.pixelSize: 12; font.weight: Font.DemiBold }
                        }
                    }
                }
                Grid {
                    id: grid
                    anchors.top: wk.bottom
                    width: parent.width
                    columns: 7
                    Repeater {
                        model: 42
                        Item {
                            id: cell
                            required property int index
                            readonly property int yr: win.viewDate.getFullYear()
                            readonly property int mo: win.viewDate.getMonth()
                            readonly property int first: win.firstWeekday(yr, mo)
                            readonly property int dim: win.daysInMonth(yr, mo)
                            readonly property int dayNum: index - first + 1
                            readonly property bool inMonth: dayNum > 0 && dayNum <= dim
                            readonly property string dayIso: inMonth ? (yr + "-" + win.pad(mo + 1) + "-" + win.pad(dayNum)) : ""
                            readonly property bool isToday: inMonth && dayIso === win.iso(new Date())
                            readonly property bool isSelected: inMonth && dayIso === win.selected
                            readonly property int evCount: inMonth ? win.eventsFor(dayIso).length : 0
                            width: grid.width / 7
                            height: monthView.cellH

                            Rectangle {
                                visible: cell.inMonth
                                y: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.min(40, cell.height - 14)
                                height: width
                                radius: width / 2
                                color: cell.isSelected ? AppTheme.accent : (cell.isToday ? AppTheme.accentSoft : "transparent")
                                Text {
                                    anchors.centerIn: parent
                                    text: cell.dayNum
                                    color: cell.isSelected ? AppTheme.accentInk : (cell.isToday ? AppTheme.accent : AppTheme.text)
                                    font.pixelSize: 17
                                    font.weight: cell.isToday || cell.isSelected ? Font.DemiBold : Font.Normal
                                }
                            }
                            Row {
                                visible: cell.evCount > 0
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 3
                                spacing: 3
                                Repeater {
                                    model: Math.min(cell.evCount, 3)
                                    Rectangle { width: 5; height: 5; radius: 2.5; color: AppTheme.accent }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: cell.inMonth
                                onClicked: win.selected = cell.dayIso
                            }
                        }
                    }
                }
                Text {
                    id: evHead
                    anchors.top: grid.bottom
                    anchors.topMargin: 8
                    leftPadding: 4
                    text: Qt.formatDate(win.selDate(), "dddd, d MMMM")
                    color: AppTheme.text
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }
                ListView {
                    anchors.top: evHead.bottom
                    anchors.topMargin: 8
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    clip: true
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds
                    model: win.eventsFor(win.selected)
                    delegate: ListRow {
                        required property var modelData
                        tappable: false
                        title: modelData.title
                        subtitle: win.evSub(modelData, false)
                        icon: "calendar"
                        Pill { icon: "trash"; flat: true; danger: true; onClicked: win.delEvent(modelData.uid) }
                    }
                }
                Text {
                    visible: win.eventsFor(win.selected).length === 0
                    anchors.top: evHead.bottom
                    anchors.topMargin: 14
                    leftPadding: 4
                    text: "No events"
                    color: AppTheme.dim
                    font.pixelSize: 15
                }
            }

            // ---- Week -------------------------------------------------------------------
            Row {
                id: weekRow
                visible: win.tab === "week"
                anchors.fill: parent
                spacing: 8
                Repeater {
                    model: 7
                    Rectangle {
                        required property int index
                        readonly property var ws: win.weekStart()
                        readonly property var dayD: new Date(ws.getFullYear(), ws.getMonth(), ws.getDate() + index)
                        readonly property string dayIso: win.iso(dayD)
                        readonly property bool isToday: dayIso === win.iso(new Date())
                        width: (weekRow.width - 48) / 7
                        height: weekRow.height
                        radius: 22
                        color: AppTheme.card
                        clip: true

                        Text {
                            id: wdName
                            anchors.top: parent.top
                            anchors.topMargin: 10
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: win.dayNames[index]
                            color: AppTheme.dim
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        Rectangle {
                            id: wdNum
                            anchors.top: wdName.bottom
                            anchors.topMargin: 4
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 36
                            height: 36
                            radius: 18
                            color: parent.isToday ? AppTheme.accent : "transparent"
                            Text { anchors.centerIn: parent; text: parent.parent.dayD.getDate(); color: parent.parent.isToday ? AppTheme.accentInk : AppTheme.text; font.pixelSize: 17; font.weight: Font.DemiBold }
                        }
                        Column {
                            anchors.top: wdNum.bottom
                            anchors.topMargin: 8
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 6
                            spacing: 4
                            Repeater {
                                model: win.eventsFor(dayIso)
                                Rectangle {
                                    required property var modelData
                                    width: parent.width
                                    height: 30
                                    radius: 10
                                    color: AppTheme.accentSoft
                                    Text { x: 6; width: parent.width - 12; anchors.verticalCenter: parent.verticalCenter; text: modelData.title; color: AppTheme.text; font.pixelSize: 12; elide: Text.ElideRight }
                                }
                            }
                        }
                    }
                }
            }

            // ---- Day --------------------------------------------------------------------
            Item {
                visible: win.tab === "day"
                anchors.fill: parent
                Flickable {
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: dayCol.height + 8
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Column {
                        id: dayCol
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: win.eventsFor(win.selected).filter(e => e.allDay)
                            Rectangle {
                                required property var modelData
                                width: dayCol.width
                                height: 48
                                radius: 18
                                color: AppTheme.accentSoft
                                Text { x: 18; width: parent.width - 80; anchors.verticalCenter: parent.verticalCenter; text: modelData.title + (modelData.type ? "  ·  " + modelData.type : ""); color: AppTheme.text; font.pixelSize: 15; elide: Text.ElideRight }
                                Pill { anchors.right: parent.right; anchors.rightMargin: 2; anchors.verticalCenter: parent.verticalCenter; icon: "close"; flat: true; onClicked: win.delEvent(modelData.uid) }
                            }
                        }
                        Repeater {
                            model: 24
                            Item {
                                required property int index
                                width: dayCol.width
                                height: Math.max(56, hourEvents.height + 18)
                                Text { x: 4; text: win.pad(index) + ":00"; color: AppTheme.dim; font.pixelSize: 12 }
                                Rectangle { x: 56; y: 8; width: parent.width - 56; height: 1; color: AppTheme.line }
                                Column {
                                    id: hourEvents
                                    x: 62
                                    y: 16
                                    width: parent.width - 62
                                    spacing: 4
                                    Repeater {
                                        model: win.eventsFor(win.selected).filter(e => !e.allDay && parseInt((e.startTime || "0:0").split(":")[0]) === index)
                                        Rectangle {
                                            required property var modelData
                                            width: parent.width
                                            height: 44
                                            radius: 16
                                            color: AppTheme.card
                                            Rectangle { x: 8; anchors.verticalCenter: parent.verticalCenter; width: 4; height: parent.height - 20; radius: 2; color: AppTheme.accent }
                                            Text { x: 24; width: parent.width - 80; anchors.verticalCenter: parent.verticalCenter; text: (modelData.startTime || "") + "  " + modelData.title; color: AppTheme.text; font.pixelSize: 15; elide: Text.ElideRight }
                                            Pill { anchors.right: parent.right; anchors.rightMargin: 2; anchors.verticalCenter: parent.verticalCenter; icon: "close"; flat: true; onClicked: win.delEvent(modelData.uid) }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- Year -------------------------------------------------------------------
            Flickable {
                visible: win.tab === "year"
                anchors.fill: parent
                contentWidth: width
                contentHeight: yearGrid.height + 8
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Grid {
                    id: yearGrid
                    width: parent.width
                    columns: width > 640 ? 4 : 3
                    spacing: 12
                    Repeater {
                        model: 12
                        Rectangle {
                            required property int index
                            readonly property int cnt: win.eventCountForMonth(win.viewDate.getFullYear(), index + 1)
                            readonly property bool cur: new Date().getFullYear() === win.viewDate.getFullYear() && new Date().getMonth() === index
                            width: (yearGrid.width - (yearGrid.columns - 1) * 12) / yearGrid.columns
                            height: 104
                            radius: 22
                            color: cur ? AppTheme.accentSoft : AppTheme.card
                            scale: ym.pressed ? 0.97 : 1
                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 18
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                Text { text: Qt.formatDate(new Date(win.viewDate.getFullYear(), index, 1), "MMMM"); color: cur ? AppTheme.accent : AppTheme.text; font.pixelSize: 19; font.weight: Font.DemiBold }
                                Text { text: cnt === 0 ? "No events" : cnt + (cnt === 1 ? " event" : " events"); color: AppTheme.dim; font.pixelSize: 13 }
                            }
                            MouseArea {
                                id: ym
                                anchors.fill: parent
                                onClicked: {
                                    win.viewDate = new Date(win.viewDate.getFullYear(), index, 1);
                                    win.tab = "month";
                                }
                            }
                        }
                    }
                }
            }

            // ---- Events -----------------------------------------------------------------
            Item {
                visible: win.tab === "events"
                anchors.fill: parent
                ListView {
                    anchors.fill: parent
                    clip: true
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds
                    model: win.allEventsSorted()
                    delegate: ListRow {
                        required property var modelData
                        tappable: false
                        title: modelData.title
                        subtitle: win.evSub(modelData, true)
                        icon: "calendar"
                        Pill { icon: "trash"; flat: true; danger: true; onClicked: win.delEvent(modelData.uid) }
                    }
                }
                Empty { visible: events.value.length === 0; anchors.centerIn: parent; icon: "calendar"; text: "No events yet.\nTap + to add one." }
            }

            // ---- Sync -------------------------------------------------------------------
            Item {
                visible: win.tab === "sync"
                anchors.fill: parent
                Rectangle {
                    width: parent.width
                    height: syncCol.height + 40
                    radius: 28
                    color: AppTheme.card
                    Column {
                        id: syncCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 20
                        spacing: 12
                        Text { width: parent.width; text: "ICS sync"; color: AppTheme.text; font.pixelSize: 20; font.weight: Font.DemiBold }
                        Row {
                            width: parent.width
                            spacing: 8
                            Field { id: icsField; width: parent.width - syncBtn.width - 8; icon: "link"; placeholder: "https://.../calendar.ics" }
                            Pill { id: syncBtn; label: win.syncing ? "Syncing…" : "Sync"; icon: "refresh"; filled: true; enabled: !win.syncing; onClicked: { win.icsUrl = icsField.text; win.syncIcs(); } }
                        }
                        Text { width: parent.width; text: "Paste an ICS URL and tap Sync. Events are merged (existing manual events kept)."; color: AppTheme.dim; font.pixelSize: 14; wrapMode: Text.WordWrap }
                    }
                }
            }
        }

        // ---- New event -----------------------------------------------------------------------
        Sheet {
            open: win.creating
            title: "New event"
            onClosed: win.creating = false

            Field { id: titleField; width: parent.width; icon: "calendar"; placeholder: "Title"; onTextChanged: win.draftTitle = text }
            Sect { text: "Type" }
            Flow {
                width: parent.width
                spacing: 8
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
            Sect { text: "Templates" }
            Flow {
                width: parent.width
                spacing: 8
                Repeater {
                    model: win.templates
                    Pill {
                        required property var modelData
                        label: modelData.name
                        onClicked: win.applyTemplate(modelData)
                    }
                }
            }
            Field { id: dateField; width: parent.width; icon: "calendar"; placeholder: "Date YYYY-MM-DD"; onTextChanged: win.draftDate = text }
            Item {
                width: parent.width
                height: 44
                Text { anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter; text: "All day"; color: AppTheme.text; font.pixelSize: 17 }
                Tog { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; checked: win.draftAllDay; onToggled: win.draftAllDay = !win.draftAllDay }
            }
            Row {
                width: parent.width
                spacing: 8
                opacity: win.draftAllDay ? 0.4 : 1
                enabled: !win.draftAllDay
                Field { id: startField; width: (parent.width - 8) / 2; icon: "clock"; placeholder: "Start HH:MM"; onTextChanged: win.draftStart = text }
                Field { id: endField; width: (parent.width - 8) / 2; icon: "clock"; placeholder: "End HH:MM"; onTextChanged: win.draftEnd = text }
            }
            Field { id: notesField; width: parent.width; icon: "note"; placeholder: "Notes"; onTextChanged: win.draftNotes = text }
            Row {
                spacing: 10
                Pill { label: "Cancel"; onClicked: win.creating = false }
                Pill { label: "Save"; icon: "check"; filled: true; onClicked: win.addEvent() }
            }
        }
    }
}
