// Single-line text input. Emits accepted(text) on Enter / focus loss.
import QtQuick
import qs.services

Rectangle {
    id: f
    property alias text: input.text
    property string placeholder: ""
    signal accepted(string text)
    implicitWidth: 260; implicitHeight: 32; radius: 8
    color: Theme.surfaceContainerHigh
    border.width: input.activeFocus ? 2 : 1; border.color: input.activeFocus ? Theme.primary : Theme.outline

    TextInput {
        id: input
        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.surfaceFg; font.pixelSize: 13; clip: true; selectByMouse: true
        onAccepted: f.accepted(text)
        onActiveFocusChanged: if (!activeFocus) f.accepted(text)
        Text { visible: !input.text && !input.activeFocus; text: f.placeholder; color: Theme.outline
               font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
    }
}
