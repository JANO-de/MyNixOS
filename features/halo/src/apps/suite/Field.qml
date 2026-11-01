import QtQuick
import qs.common

// Single-line input (same pill as the Files filter box): optional line icon, accent ring while focused.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property string icon: ""
    signal accepted

    function forceFocus() { input.forceActiveFocus(); }

    implicitHeight: 44
    radius: 22
    color: AppTheme.card
    border.width: input.activeFocus ? 2 : 0
    border.color: AppTheme.accent

    Ico {
        visible: root.icon !== ""
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: 20
        color: AppTheme.dim
    }
    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: root.icon !== "" ? 44 : 20
        anchors.rightMargin: 16
        verticalAlignment: TextInput.AlignVCenter
        color: AppTheme.text
        selectionColor: AppTheme.accent
        selectedTextColor: AppTheme.accentInk
        font.pixelSize: 16
        clip: true
        selectByMouse: true
        onAccepted: root.accepted()
        Text {
            visible: input.text === ""
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: root.placeholder
            color: AppTheme.dim
            font.pixelSize: 16
            elide: Text.ElideRight
        }
    }
}
