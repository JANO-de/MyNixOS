import QtQuick
import Quickshell
import qs.common
import qs.suite

ShellRoot {
    SuiteWindow {
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
            store.value = [{ id: id, text: t, done: false, due: due }].concat(store.value);
            store.save();
            if (due !== "")
                Quickshell.execDetached(["sh", alarmSh, "set", id, due, t]);
            input.text = "";
            whenSel = 0;
        }
        function toggle(i) {
            const l = store.value.slice();
            l[i] = Object.assign({}, l[i], { done: !l[i].done });
            store.value = l;
            store.save();
            if (l[i].done && l[i].due !== "")
                Quickshell.execDetached(["sh", alarmSh, "clear", l[i].id]);
        }
        function del(i) {
            Quickshell.execDetached(["sh", alarmSh, "clear", store.value[i].id]);
            store.value = store.value.filter((r, j) => j !== i);
            store.save();
        }

        JsonStore { id: store; name: "reminders"; fallback: [] }

        Column {
            id: form
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 12
            Field { id: input; width: parent.width; icon: "plus"; placeholder: "New reminder (Enter to add)"; onAccepted: win.add() }
            Flow {
                width: parent.width
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
        }

        ListView {
            anchors.top: form.bottom
            anchors.topMargin: 14
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 16
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            model: store.value
            delegate: ListRow {
                required property var modelData
                required property int index
                title: modelData.text
                subtitle: modelData.due
                dimTitle: modelData.done
                strike: modelData.done
                subtitleColor: (!modelData.done && modelData.due !== "" && modelData.due < win.stamp(new Date())) ? AppTheme.danger : AppTheme.dim
                onClicked: win.toggle(index)
                lead: [ Check { checked: modelData.done; onToggled: win.toggle(index) } ]
                Pill { icon: "trash"; flat: true; danger: true; onClicked: win.del(index) }
            }
        }

        Empty {
            visible: store.value.length === 0
            anchors.centerIn: parent
            icon: "bell"
            text: "No reminders"
        }
    }
}
