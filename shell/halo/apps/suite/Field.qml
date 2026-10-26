import QtQuick
import qs.common

Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    signal accepted

    function forceFocus() { input.forceActiveFocus(); }

    implicitHeight: 48
    radius: 24
    color: AppTheme.card
    border.width: input.activeFocus ? 2 : 0
    border.color: AppTheme.accent

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        verticalAlignment: TextInput.AlignVCenter
        color: AppTheme.text
        font.pixelSize: 17
        clip: true
        selectByMouse: true
        onAccepted: root.accepted()
        Text {
            visible: input.text === ""
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: root.placeholder
            color: AppTheme.dim
            font.pixelSize: 17
        }
    }
}
