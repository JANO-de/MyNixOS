// Calendar sources (shown in the island calendar panel, the calendar widget and the week strip).
// Add an ICS link, or a folder of .ics files (CalDAV via vdirsyncer, see docs/calendar-sync.md).
import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

Page {
    id: pg
    title: "Calendar"
    property string nName: ""
    property string nKind: "url"
    property string nValue: ""
    property string nColor: "#8bd5a0"
    readonly property var sources: Config.calendar.sources ? Array.from(Config.calendar.sources) : []

    function addSource() {
        const name = nName.trim(), value = nValue.trim();
        if (!name || !value || sources.some(s => s.name === name)) return;
        Config.calendar.sources = sources.concat([{ name: name, kind: nKind, value: value, color: nColor }]);
        nName = ""; nValue = "";
    }

    SettingRow { label: "Sync calendars"; hint: Agenda.status
        Toggle { checked: Config.calendar.enabled; onToggled: Config.calendar.enabled = !Config.calendar.enabled } }
    SettingRow { label: "Sync now"
        PillButton { label: Agenda.syncing ? "Syncing..." : "Sync"; icon: "sync"; enabled: !Agenda.syncing; onClicked: Agenda.sync() } }
    SettingRow { label: "Sync every" }
    Chips { width: parent.width; current: String(Config.calendar.syncMinutes)
            model: [ { label: "5 min", value: "5" }, { label: "15 min", value: "15" }, { label: "30 min", value: "30" }, { label: "1 hour", value: "60" } ]
            onPicked: v => Config.calendar.syncMinutes = Number(v) }
    SettingRow { label: "Run vdirsyncer first"; hint: "For CalDAV: syncs your server into a local folder before reading it"
        Toggle { checked: Config.calendar.vdirsyncer; onToggled: Config.calendar.vdirsyncer = !Config.calendar.vdirsyncer } }
    SettingRow { label: "Week starts on Monday"
        Toggle { checked: Config.calendar.mondayFirst; onToggled: Config.calendar.mondayFirst = !Config.calendar.mondayFirst } }

    Text { text: "Sources"; color: Theme.surfaceFg; font.pixelSize: 15; font.weight: Font.DemiBold; topPadding: 12 }
    Text { visible: pg.sources.length === 0; text: "None yet. Add one below."; color: Theme.surfaceFgDim; font.pixelSize: 12 }
    Repeater {
        model: pg.sources
        Rectangle {
            required property var modelData
            required property int index
            width: pg.width - 56; height: 46; radius: 12; color: Theme.surfaceContainer
            Rectangle { id: dot; width: 12; height: 12; radius: 6; color: modelData.color; anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter } }
            Column {
                anchors { left: dot.right; leftMargin: 12; right: del.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                Text { width: parent.width; elide: Text.ElideRight; text: modelData.name + "  ·  " + (modelData.kind === "url" ? "ICS link" : "Folder")
                       color: Theme.surfaceFg; font.pixelSize: 13 }
                Text { width: parent.width; elide: Text.ElideMiddle; text: modelData.value; color: Theme.surfaceFgDim; font.pixelSize: 11 }
            }
            IconButton { id: del; icon: "delete"; diameter: 30; iconSize: 17; anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                         onClicked: Config.calendar.sources = pg.sources.filter((s, i) => i !== index) }
        }
    }

    Text { text: "Add a source"; color: Theme.surfaceFg; font.pixelSize: 15; font.weight: Font.DemiBold; topPadding: 12 }
    SettingRow { label: "Name"; Field { text: pg.nName; placeholder: "Personal"; onAccepted: t => pg.nName = t } }
    SettingRow { label: "Type" }
    Chips { width: parent.width; current: pg.nKind
            model: [ { label: "ICS link (URL)", value: "url" }, { label: "Folder of .ics (CalDAV)", value: "folder" } ]
            onPicked: v => pg.nKind = v }
    SettingRow { label: pg.nKind === "url" ? "ICS URL" : "Folder"
                 hint: pg.nKind === "url" ? "https://... .ics" : "~/.local/share/dynisland/calendars"
        Field { width: 300; text: pg.nValue; placeholder: pg.nKind === "url" ? "https://calendar.google.com/.../basic.ics" : "~/.local/share/dynisland/calendars"
                onAccepted: t => pg.nValue = t } }
    Swatches { width: parent.width; current: pg.nColor; colors: ["#8bd5a0", "#a8c7fa", "#f2b8b5", "#f9d56e", "#d0a8ff", "#ffb68a"]; onPicked: c => pg.nColor = c }
    SettingRow { label: ""
        PillButton { label: "Add source"; icon: "add"; filled: true; onClicked: pg.addSource() } }

    Text {
        width: parent.width - 56; wrapMode: Text.WordWrap; color: Theme.surfaceFgDim; font.pixelSize: 12; topPadding: 10; lineHeight: 1.15
        text: "Google: Calendar settings > Integrate calendar > \"Secret address in iCal format\" (read-only link).\n" +
              "Outlook / Proton / Nextcloud public links: paste the published .ics link.\n" +
              "CalDAV (Nextcloud, iCloud, Fastmail, Radicale, Google with OAuth): set up vdirsyncer, add a Folder source and turn on \"Run vdirsyncer first\". See docs/calendar-sync.md.\n" +
              "Tuta has no CalDAV or ICS feed: export your calendar to .ics into a folder and add that folder."
    }
}
