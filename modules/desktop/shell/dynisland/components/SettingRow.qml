// One settings line: label (+hint) on the left, controls (children) on the right.
import QtQuick
import qs.services

Item {
    id: r
    property string label: ""
    property string hint: ""
    property bool wide: false   // true: content stacks full-width below the label instead of beside it (grids, long lists)
    default property alias content: slot.data
    width: parent ? parent.width : 400
    readonly property bool tile: !(parent && parent.objectName === "plainCol")   // card tile on pages; plain rows inside menus
    implicitHeight: r.wide ? (lab.implicitHeight + slot.implicitHeight + 38)
                            : Math.max(tile ? 56 : 52, lab.implicitHeight + 20, slot.implicitHeight + 16)

    Rectangle {   // tile background (same glass language as dock / island)
        visible: r.tile; anchors { fill: parent; topMargin: 3; bottomMargin: 3 } radius: 16
        color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.7)
        border.width: 1; border.color: Glass.outline
    }

    readonly property int sideMargin: r.tile ? 18 : 0
    Column {   // label: left-of-controls normally, full-width-on-top in wide mode
        id: lab
        anchors.left: parent.left; anchors.leftMargin: r.sideMargin; anchors.top: parent.top; anchors.topMargin: r.wide ? 14 : 0
        anchors.right: r.wide ? parent.right : slot.left
        anchors.rightMargin: r.wide ? r.sideMargin : (slot.children.length > 0 ? 16 : 0)
        anchors.verticalCenter: r.wide ? undefined : parent.verticalCenter
        spacing: 2
        Text { width: parent.width; wrapMode: Text.WordWrap; text: r.label; color: Theme.surfaceFg; font.pixelSize: 14; font.weight: Font.Medium }
        Text { width: parent.width; wrapMode: Text.WordWrap; visible: r.hint !== ""; text: r.hint; color: Theme.surfaceFgDim; font.pixelSize: 12 }
    }
    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } visible: !r.tile; height: 1; color: Theme.outline; opacity: 0.2 }   // hairline divider
    Row {   // controls: right-of-label normally, full-width below it in wide mode
        id: slot
        anchors.right: parent.right; anchors.rightMargin: r.sideMargin
        anchors.top: r.wide ? lab.bottom : undefined; anchors.topMargin: r.wide ? 10 : 0
        anchors.verticalCenter: r.wide ? undefined : parent.verticalCenter
        anchors.left: r.wide ? parent.left : undefined; anchors.leftMargin: r.wide ? r.sideMargin : 0
        spacing: 8
    }
}
