import QtQuick
import qs.services

// Notes: shows the saved text; tap opens the editor window (NoteEdit.qml, needs keyboard focus).
Item {
    id: root
    property var inst: null
    readonly property string txt: inst && inst.cfg && inst.cfg.text ? inst.cfg.text : ""

    Text {
        id: head
        text: "Notes"
        color: Theme.accent
        font.pixelSize: 15
        font.weight: Font.DemiBold
    }
    Text {
        anchors.top: head.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        text: root.txt !== "" ? root.txt : "Tap to write a note"
        color: root.txt !== "" ? Theme.text : Theme.dim
        font.pixelSize: 15
        wrapMode: Text.Wrap
        elide: Text.ElideRight
    }
    MouseArea {
        anchors.fill: parent
        enabled: !Home.editing && root.inst !== null
        onClicked: UI.openNote(root.inst.id)
    }
}
