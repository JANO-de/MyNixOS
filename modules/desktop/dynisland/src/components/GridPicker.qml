// Scrollable grid of square icon tiles, one per item — for pickers where Chips' single
// row collides with the row's own label/hint text once there are more than a few options
// (provider list, add-provider presets). model: [{label, value, icon, added}]. Emits picked(value).
import QtQuick
import QtQuick.Controls
import qs.services
import qs.components

Rectangle {
    id: g
    property var model: []
    property var current
    property int tileSize: 72
    property int maxHeight: 176
    signal picked(var value)

    width: parent ? parent.width : 320
    radius: 12; color: Theme.surfaceContainer; border.width: 1; border.color: Theme.outline
    implicitHeight: Math.min(maxHeight, flow.height + 16)
    height: implicitHeight
    clip: true

    Flickable {
        anchors.fill: parent; anchors.margins: 8
        contentHeight: flow.height
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: flow.height > height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff }

        Flow {
            id: flow
            width: parent.width; spacing: 8
            Repeater {
                model: g.model
                Rectangle {
                    id: tile
                    required property var modelData
                    readonly property bool sel: modelData.value === g.current
                    width: g.tileSize; height: g.tileSize; radius: 10
                    color: sel ? Theme.primary : (ma.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainerHigh)
                    opacity: ma.containsMouse && !sel ? 1 : (sel ? 1 : 0.9)
                    border.width: 1; border.color: sel ? Qt.lighter(Theme.primary, 1.3) : Theme.outline
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Column {
                        anchors.centerIn: parent; spacing: 4; width: parent.width - 8
                        Icon { anchors.horizontalCenter: parent.horizontalCenter
                               name: tile.modelData.icon || "smart_toy"; size: 20
                               color: tile.sel ? Theme.primaryFg : Theme.surfaceFg }
                        Text { width: parent.width; horizontalAlignment: Text.AlignHCenter
                               text: tile.modelData.label; font.pixelSize: 11; elide: Text.ElideRight
                               maximumLineCount: 2; wrapMode: Text.WordWrap
                               color: tile.sel ? Theme.primaryFg : Theme.surfaceFg }
                    }
                    Rectangle {   // small check badge when this preset is already added
                        visible: !!tile.modelData.added && !tile.sel
                        width: 14; height: 14; radius: 7
                        anchors { top: parent.top; right: parent.right; margins: 4 }
                        color: Theme.primary
                        Text { anchors.centerIn: parent; text: "\u2713"; font.pixelSize: 9; color: Theme.primaryFg }
                    }
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: g.picked(tile.modelData.value) }
                }
            }
        }
    }
}
