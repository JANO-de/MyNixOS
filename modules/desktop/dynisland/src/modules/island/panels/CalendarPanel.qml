// Month grid with event dots + the agenda of the selected day. Sources: Settings > Calendar.
import QtQuick
import qs.config
import qs.services
import qs.components

PanelFrame {
    id: p
    title: Qt.formatDate(view, "MMMM yyyy"); icon: "calendar_month"
    property date view: new Date(new Date().getFullYear(), new Date().getMonth(), 1)
    property date selected: new Date()
    readonly property bool monFirst: Config.calendar.mondayFirst
    readonly property int offset: monFirst ? (view.getDay() + 6) % 7 : view.getDay()
    readonly property int dim: new Date(view.getFullYear(), view.getMonth() + 1, 0).getDate()
    readonly property var dayEvents: Agenda.eventsOn(selected)
    function sameDay(a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate() }
    function shift(n) { view = new Date(view.getFullYear(), view.getMonth() + n, 1) }

    // month navigation + sync (top right, left of the close button)
    Row {
        parent: p; z: 5; spacing: 6
        anchors { top: parent.top; right: parent.right; topMargin: 15; rightMargin: 56 }
        Repeater {
            model: [ { i: "chevron_left", f: 0 }, { i: "today", f: 1 }, { i: "chevron_right", f: 2 }, { i: "sync", f: 3 } ]
            Rectangle {
                required property var modelData
                width: 28; height: 28; radius: 14; color: bma.containsMouse ? "#33ffffff" : "#18ffffff"
                Icon { anchors.centerIn: parent; name: modelData.i; size: 17; color: modelData.f === 3 && Agenda.syncing ? Theme.primary : "white" }
                MouseArea { id: bma; anchors.fill: parent; hoverEnabled: true
                    onClicked: { if (modelData.f === 0) p.shift(-1); else if (modelData.f === 2) p.shift(1)
                                 else if (modelData.f === 1) { p.view = new Date(new Date().getFullYear(), new Date().getMonth(), 1); p.selected = new Date() }
                                 else Agenda.sync() } }
            }
        }
    }

    Column {
        anchors.fill: parent; spacing: 6
        Row {   // weekday header
            spacing: 4
            Repeater {
                model: p.monFirst ? ["M", "T", "W", "T", "F", "S", "S"] : ["S", "M", "T", "W", "T", "F", "S"]
                Text { required property string modelData; width: 38; horizontalAlignment: Text.AlignHCenter
                       text: modelData; color: "#88ffffff"; font.pixelSize: 11 }
            }
        }
        Grid {
            columns: 7; spacing: 4
            Repeater {
                model: 42
                Rectangle {
                    required property int index
                    readonly property int day: index - p.offset + 1
                    readonly property bool valid: day >= 1 && day <= p.dim
                    readonly property date dt: new Date(p.view.getFullYear(), p.view.getMonth(), day)
                    readonly property bool isToday: valid && p.sameDay(dt, new Date())
                    readonly property bool isSel: valid && p.sameDay(dt, p.selected)
                    width: 38; height: 30; radius: 15
                    color: isToday ? Theme.primary : (isSel ? "#33ffffff" : "transparent")
                    Text { anchors.centerIn: parent; visible: parent.valid; text: parent.day; font.pixelSize: 13
                           color: parent.isToday ? Theme.primaryFg : "white" }
                    Rectangle {   // event dot
                        visible: parent.valid && Agenda.hasEvents(parent.dt)
                        width: 4; height: 4; radius: 2; color: parent.isToday ? Theme.primaryFg : Theme.primary
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 1 }
                    }
                    MouseArea { anchors.fill: parent; enabled: parent.valid; onClicked: p.selected = parent.dt }
                }
            }
        }

        Text { text: Qt.formatDate(p.selected, "dddd, d MMMM"); color: "white"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 4 }
        Flickable {
            width: parent.width; height: 120; clip: true; contentHeight: ag.height; boundsBehavior: Flickable.StopAtBounds
            Column {
                id: ag; width: parent.width; spacing: 6
                Text { visible: p.dayEvents.length === 0; color: "#77ffffff"; font.pixelSize: 12
                       text: Agenda.status === "No calendar sources yet" ? "No calendar connected. Add one in Settings > Calendar." : "Nothing planned" }
                Repeater {
                    model: p.dayEvents
                    Row {
                        required property var modelData
                        spacing: 8; width: ag.width
                        Rectangle { width: 4; height: 32; radius: 2; color: modelData.color }
                        Column {
                            width: parent.width - 14
                            Text { width: parent.width; elide: Text.ElideRight; text: modelData.title; color: "white"; font.pixelSize: 13 }
                            Text { width: parent.width; elide: Text.ElideRight; color: "#99ffffff"; font.pixelSize: 11
                                   text: (modelData.allDay ? "All day" : Qt.formatTime(modelData.start, "hh:mm") + " - " + Qt.formatTime(modelData.end, "hh:mm"))
                                         + (modelData.location ? "  " + modelData.location : "") }
                        }
                    }
                }
            }
        }
        Text { text: Agenda.status; color: "#66ffffff"; font.pixelSize: 10 }
    }
}
