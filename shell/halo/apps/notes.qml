import QtQuick
import Quickshell
import qs.common
import qs.suite

ShellRoot {
    SuiteWindow {
        id: win

        title: "Notes"
        implicitWidth: 1000
        implicitHeight: 700

        property string cur: ""
        property bool loading: false
        readonly property bool narrow: width < 720   // one pane at a time (back button)
        readonly property var shown: {
            const q = search.text.trim().toLowerCase();
            const l = notes.value.filter(n => q === "" || n.text.toLowerCase().indexOf(q) >= 0);
            return l.sort((a, b) => b.ts - a.ts);
        }
        function titleOf(n) {
            const t = n.text.split("\n")[0].trim();
            return t === "" ? "New note" : t;
        }
        function previewOf(n) {
            const l = n.text.split("\n").map(s => s.trim()).filter(s => s !== "");
            return Qt.formatDateTime(new Date(n.ts), "d MMM, HH:mm") + (l.length > 1 ? "  ·  " + l[1] : "");
        }
        function open(id) {
            cur = id;
            loading = true;
            const n = notes.value.find(x => x.id === id);
            edit.text = n ? n.text : "";
            loading = false;
        }
        function add() {
            const id = String(Date.now());
            notes.value = notes.value.concat([{ id: id, text: "", ts: Date.now() }]);
            notes.save();
            open(id);
            edit.forceActiveFocus();
        }
        function del() {
            if (cur === "")
                return;
            notes.value = notes.value.filter(n => n.id !== cur);
            notes.save();
            cur = "";
            edit.text = "";
        }

        JsonStore { id: notes; name: "notes"; fallback: [] }

        canBack: narrow && cur !== ""
        onBackClicked: cur = ""
        heading: narrow && cur !== "" ? titleOf(notes.value.find(x => x.id === cur) || { text: "" }) : title

        actions: [
            Pill { icon: "plus"; filled: true; onClicked: win.add() },
            Pill { icon: "trash"; danger: true; enabled: win.cur !== ""; onClicked: win.del() }
        ]

        Item {
            anchors.fill: parent
            anchors.margins: 16

            Column {
                id: side
                visible: !win.narrow || win.cur === ""
                width: win.narrow ? parent.width : 320
                height: parent.height
                spacing: 10
                Field { id: search; width: parent.width; icon: "search"; placeholder: "Search notes" }
                ListView {
                    width: parent.width
                    height: parent.height - 54
                    clip: true
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds
                    model: win.shown
                    delegate: ListRow {
                        required property var modelData
                        title: win.titleOf(modelData)
                        subtitle: win.previewOf(modelData)
                        selected: win.cur === modelData.id
                        onClicked: win.open(modelData.id)
                    }
                }
            }

            Rectangle {
                visible: !win.narrow || win.cur !== ""
                anchors.left: win.narrow ? parent.left : side.right
                anchors.leftMargin: win.narrow ? 0 : 14
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                radius: 28
                color: AppTheme.card

                Flickable {
                    id: fl
                    anchors.fill: parent
                    anchors.margins: 22
                    contentWidth: width
                    contentHeight: edit.contentHeight + 40
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    TextEdit {
                        id: edit
                        width: fl.width
                        enabled: win.cur !== ""
                        color: AppTheme.text
                        selectionColor: AppTheme.accent
                        selectedTextColor: AppTheme.accentInk
                        font.pixelSize: 18
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        onTextChanged: {
                            if (win.loading || win.cur === "")
                                return;
                            notes.value = notes.value.map(n => n.id === win.cur ? { id: n.id, text: text, ts: Date.now() } : n);
                            notes.save();
                        }
                    }
                }
                Empty {
                    visible: win.cur === ""
                    anchors.centerIn: parent
                    icon: "note"
                    text: "Select a note or tap +"
                }
            }
        }
    }
}
