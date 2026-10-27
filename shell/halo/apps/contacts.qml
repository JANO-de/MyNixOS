import QtQuick
import Quickshell
import qs.common
import qs.suite

ShellRoot {
    AppWindow {
        id: win

        title: "Contacts"
        implicitWidth: 1000
        implicitHeight: 700

        property string cur: ""
        property bool loading: false
        readonly property var shown: {
            const q = search.text.trim().toLowerCase();
            const l = contacts.value.filter(c => q === "" || (c.name + " " + c.phone + " " + c.email).toLowerCase().indexOf(q) >= 0);
            return l.sort((a, b) => a.name.localeCompare(b.name));
        }
        function open(id) {
            loading = true;
            cur = id;
            const c = contacts.value.find(x => x.id === id) || { name: "", phone: "", email: "", note: "" };
            fName.text = c.name;
            fPhone.text = c.phone;
            fMail.text = c.email;
            fNote.text = c.note;
            loading = false;
        }
        function commit() {
            if (loading || cur === "")
                return;
            contacts.value = contacts.value.map(c => c.id === cur ? { id: c.id, name: fName.text, phone: fPhone.text, email: fMail.text, note: fNote.text } : c);
            contacts.save();
        }
        function add() {
            const id = String(Date.now());
            contacts.value = contacts.value.concat([{ id: id, name: "New contact", phone: "", email: "", note: "" }]);
            contacts.save();
            open(id);
            fName.forceFocus();
        }
        function del() {
            contacts.value = contacts.value.filter(c => c.id !== cur);
            contacts.save();
            cur = "";
        }

        JsonStore { id: contacts; name: "contacts"; fallback: [] }

        actions: [
            Pill { glyph: "+"; onClicked: win.add() },
            Pill { glyph: "🗑"; danger: true; enabled: win.cur !== ""; onClicked: win.del() }
        ]

        Item {
            anchors.fill: parent
            anchors.margins: 12

            Column {
                id: side
                width: 340
                height: parent.height
                spacing: 8
                Field { id: search; width: parent.width; placeholder: "Search contacts" }
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
                        color: win.cur === modelData.id ? AppTheme.accentSoft : (ct.pressed ? AppTheme.cardHigh : AppTheme.card)
                        Rectangle {
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 40
                            height: 40
                            radius: 20
                            color: AppTheme.accentSoft
                            Text { anchors.centerIn: parent; text: modelData.name.charAt(0).toUpperCase(); color: AppTheme.accent; font.pixelSize: 20 }
                        }
                        Column {
                            x: 66
                            width: parent.width - 80
                            anchors.verticalCenter: parent.verticalCenter
                            Text { width: parent.width; text: modelData.name; color: AppTheme.text; font.pixelSize: 17; elide: Text.ElideRight }
                            Text { width: parent.width; text: modelData.phone !== "" ? modelData.phone : modelData.email; color: AppTheme.dim; font.pixelSize: 12; elide: Text.ElideRight }
                        }
                        MouseArea { id: ct; anchors.fill: parent; onClicked: win.open(modelData.id) }
                    }
                }
            }

            Column {
                visible: win.cur !== ""
                anchors.left: side.right
                anchors.leftMargin: 20
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 12
                Field { id: fName; width: parent.width; placeholder: "Name"; onTextChanged: win.commit() }
                Field { id: fPhone; width: parent.width; placeholder: "Phone"; onTextChanged: win.commit() }
                Field { id: fMail; width: parent.width; placeholder: "Email"; onTextChanged: win.commit() }
                Field { id: fNote; width: parent.width; placeholder: "Note"; onTextChanged: win.commit() }
            }
            Text {
                visible: win.cur === ""
                anchors.left: side.right
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                text: "Select a contact or tap +"
                color: AppTheme.dim
                font.pixelSize: 18
            }
        }
    }
}
