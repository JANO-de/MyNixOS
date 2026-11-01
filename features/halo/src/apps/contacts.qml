import QtQuick
import Quickshell
import qs.common
import qs.suite

ShellRoot {
    SuiteWindow {
        id: win

        title: "Contacts"
        implicitWidth: 1000
        implicitHeight: 700

        property string cur: ""
        property bool loading: false
        readonly property bool narrow: width < 720   // one pane at a time (back button)
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

        canBack: narrow && cur !== ""
        onBackClicked: cur = ""

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
                width: win.narrow ? parent.width : 340
                height: parent.height
                spacing: 10
                Field { id: search; width: parent.width; icon: "search"; placeholder: "Search contacts" }
                ListView {
                    width: parent.width
                    height: parent.height - 54
                    clip: true
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds
                    model: win.shown
                    delegate: ListRow {
                        required property var modelData
                        title: modelData.name
                        subtitle: modelData.phone !== "" ? modelData.phone : modelData.email
                        letter: modelData.name.charAt(0).toUpperCase()
                        selected: win.cur === modelData.id
                        onClicked: win.open(modelData.id)
                    }
                }
            }

            Flickable {
                visible: win.cur !== ""
                anchors.left: win.narrow ? parent.left : side.right
                anchors.leftMargin: win.narrow ? 0 : 24
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                contentWidth: width
                contentHeight: form.height + 20
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: form
                    width: parent.width
                    spacing: 12
                    Item {
                        width: parent.width
                        height: 120
                        Badge {
                            anchors.centerIn: parent
                            diameter: 96
                            letter: fName.text.charAt(0).toUpperCase()
                            icon: fName.text === "" ? "user" : ""
                        }
                    }
                    Field { id: fName; width: parent.width; icon: "user"; placeholder: "Name"; onTextChanged: win.commit() }
                    Field { id: fPhone; width: parent.width; icon: "phone"; placeholder: "Phone"; onTextChanged: win.commit() }
                    Field { id: fMail; width: parent.width; icon: "mail"; placeholder: "Email"; onTextChanged: win.commit() }
                    Field { id: fNote; width: parent.width; icon: "note"; placeholder: "Note"; onTextChanged: win.commit() }
                }
            }
            Item {
                visible: win.cur === "" && !win.narrow
                anchors.left: side.right
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                Empty { anchors.centerIn: parent; icon: "user"; text: "Select a contact or tap +" }
            }
        }
    }
}
