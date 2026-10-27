import QtQuick
import Quickshell
import qs.common
import qs.suite

ShellRoot {
    AppWindow {
        id: win

        title: "Notes"
        implicitWidth: 1000
        implicitHeight: 700

        property string cur: ""
        property bool loading: false
        readonly property var shown: {
            const q = search.text.trim().toLowerCase();
            const l = notes.value.filter(n => q === "" || n.text.toLowerCase().indexOf(q) >= 0);
            return l.sort((a, b) => b.ts - a.ts);
        }
        function titleOf(n) {
            const t = n.text.split("\n")[0].trim();
            return t === "" ? "New note" : t;
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

        actions: [
            Pill { glyph: "+"; onClicked: win.add() },
            Pill { glyph: "🗑"; danger: true; enabled: win.cur !== ""; onClicked: win.del() }
        ]

        Item {
            anchors.fill: parent
            anchors.margins: 12

            Column {
                id: side
                width: 320
                height: parent.height
                spacing: 8
                Field { id: search; width: parent.width; placeholder: "Search notes" }
                ListView {
                    width: parent.width
                    height: parent.height - 56
                    clip: true
                    spacing: 6
                    model: win.shown
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: 64
                        radius: 20
                        color: win.cur === modelData.id ? AppTheme.accentSoft : (nt.pressed ? AppTheme.cardHigh : AppTheme.card)
                        Column {
                            x: 18
                            width: parent.width - 36
                            anchors.verticalCenter: parent.verticalCenter
                            Text { width: parent.width; text: win.titleOf(modelData); color: AppTheme.text; font.pixelSize: 17; elide: Text.ElideRight }
                            Text { width: parent.width; text: Qt.formatDateTime(new Date(modelData.ts), "d MMM, HH:mm"); color: AppTheme.dim; font.pixelSize: 12 }
                        }
                        MouseArea { id: nt; anchors.fill: parent; onClicked: win.open(modelData.id) }
                    }
                }
            }

            Rectangle {
                anchors.left: side.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                radius: 28
                color: AppTheme.card

                Flickable {
                    id: fl
                    anchors.fill: parent
                    anchors.margins: 20
                    contentWidth: width
                    contentHeight: edit.contentHeight + 40
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    TextEdit {
                        id: edit
                        width: fl.width
                        enabled: win.cur !== ""
                        color: AppTheme.text
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
                Text {
                    visible: win.cur === ""
                    anchors.centerIn: parent
                    text: "Select a note or tap +"
                    color: AppTheme.dim
                    font.pixelSize: 18
                }
            }
        }
    }
}
