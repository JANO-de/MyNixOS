// One settings line: label (+hint) on the left, controls (children) on the right.
import QtQuick
import qs.services

Item {
    id: r
    property string label: ""
    property string hint: ""
    default property alias content: slot.data
    width: parent ? parent.width : 400
    readonly property bool tile: !(parent && parent.objectName === "plainCol")   // card tile on pages; plain rows inside menus
    implicitHeight: Math.max(tile ? 56 : 52, lab.implicitHeight + 20, slot.implicitHeight + 16)

    Rectangle {   // tile background (same glass language as dock / island)
        visible: r.tile; anchors { fill: parent; topMargin: 3; bottomMargin: 3 } radius: 16
        color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.7)
        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.1)
    }
    Column {   // label wraps to a new line before it reaches the controls
        id: lab
        anchors { left: parent.left; leftMargin: r.tile ? 18 : 0; right: slot.left; rightMargin: slot.children.length > 0 ? 16 : 0; verticalCenter: parent.verticalCenter }
        spacing: 2
        Text { width: parent.width; wrapMode: Text.WordWrap; text: r.label; color: Theme.surfaceFg; font.pixelSize: 14; font.weight: Font.Medium }
        Text { width: parent.width; wrapMode: Text.WordWrap; visible: r.hint !== ""; text: r.hint; color: Theme.surfaceFgDim; font.pixelSize: 12 }
    }
    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } visible: !r.tile; height: 1; color: Theme.outline; opacity: 0.2 }   // hairline divider
    Row { id: slot; anchors { right: parent.right; rightMargin: r.tile ? 14 : 0; verticalCenter: parent.verticalCenter } spacing: 8 }
}
