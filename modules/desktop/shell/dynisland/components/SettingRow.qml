// One settings line: label (+hint) on the left, controls (children) on the right.
import QtQuick
import qs.services

Item {
    id: r
    property string label: ""
    property string hint: ""
    default property alias content: slot.data
    width: parent ? parent.width : 400
    implicitHeight: 54

    Column {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        spacing: 2
        Text { text: r.label; color: Theme.surfaceFg; font.pixelSize: 14 }
        Text { visible: r.hint !== ""; text: r.hint; color: Theme.surfaceFgDim; font.pixelSize: 11 }
    }
    Row { id: slot; anchors { right: parent.right; verticalCenter: parent.verticalCenter } spacing: 8 }
}
