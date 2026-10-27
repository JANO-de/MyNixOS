import QtQuick
import Quickshell
import qs.common
import qs.suite

ShellRoot {
    AppWindow {
        id: win

        title: "Reminders"
        implicitWidth: 560
        implicitHeight: 760

        readonly property string alarmSh: String(Qt.resolvedUrl("suite/alarm.sh")).replace("file://", "")
        property int whenSel: 0
        function pad(n) { return (n < 10 ? "0" : "") + n; }
        function stamp(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) + " " + pad(d.getHours()) + ":" + pad(d.getMinutes()); }
        function dueFor(sel) {
            const d = new Date();
            if (sel === 1) d.setMinutes(d.getMinutes() + 10);
            else if (sel === 2) d.setHours(d.getHours() + 1);
            else if (sel === 3) { d.setDate(d.getDate() + 1); d.setHours(9, 0, 0, 0); }
            else return "";
            return stamp(d);
        }
        function add() {
            const t = input.text.trim();
            if (t === "")
                return;
            const id = String(Date.now());
            const due = dueFor(whenSel);
            store.data = [{ id: id, text: t, done: false, due: due }].concat(store.data);
            store.save();
            if (due !== "")
                Quickshell.execDetached(["sh", alarmSh, "set", id, due, t]);
            input.text = "";
            whenSel = 0;
        }
        function toggle(i) {
            const l = store.data.slice();
            l[i] = Object.assign({}, l[i], { done: !l[i].done });
            store.data = l;
            store.save();
            if (l[i].done && l[i].due !== "")
                Quickshell.execDetached(["sh", alarmSh, "clear", l[i].id]);
        }
        function del(i) {
            Quickshell.execDetached(["sh", alarmSh, "clear", store.data[i].id]);
            store.data = store.data.filter((r, j) => j !== i);
            store.save();
        }

        JsonStore { id: store; name: "reminders"; fallback: [] }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            Field { id: input; width: parent.width; placeholder: "New reminder (Enter to add)"; onAccepted: win.add() }
            Row {
                spacing: 8
                Repeater {
                    model: ["No time", "In 10 min", "In 1 h", "Tomorrow 9:00"]
                    Pill {
                        required property string modelData
                        required property int index
                        label: modelData
                        on: win.whenSel === index
                        onClicked: win.whenSel = index
                    }
                }
            }
            ListView {
                width: parent.width
                height: parent.height - 120
                clip: true
                spacing: 6
                model: store.data
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: 64
                    radius: 22
                    color: AppTheme.card
                    Rectangle {
                        x: 16
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: 14
                        color: modelData.done ? AppTheme.accent : "transparent"
                        border.width: 2
                        border.color: AppTheme.accent
                        Text { visible: modelData.done; anchors.centerIn: parent; text: "✓"; color: AppTheme.accentInk; font.pixelSize: 16 }
                        MouseArea { anchors.fill: parent; anchors.margins: -10; onClicked: win.toggle(index) }
                    }
                    Column {
                        x: 60
                        width: parent.width - 120
                        anchors.verticalCenter: parent.verticalCenter
                        Text { width: parent.width; text: modelData.text; color: modelData.done ? AppTheme.dim : AppTheme.text; font.pixelSize: 17; font.strikeout: modelData.done; elide: Text.ElideRight }
                        Text { visible: modelData.due !== ""; width: parent.width; text: modelData.due; color: AppTheme.dim; font.pixelSize: 12 }
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✕"
                        color: AppTheme.dim
                        font.pixelSize: 16
                        MouseArea { anchors.fill: parent; anchors.margins: -12; onClicked: win.del(index) }
                    }
                }
            }
        }
    }
}
