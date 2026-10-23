import QtQuick
import qs.services

// Control center tiles. Tap = toggle, long-press = edit mode (jiggle),
// drag to reorder, "-" to remove. Layout is responsive (4 columns wide, 2 narrow).
Item {
    id: root

    property bool editing: false
    property int cols: width >= 420 ? 4 : 2
    property int gap: 12
    signal closeRequested
    signal editRequested

    readonly property real cell: (width - gap * (cols - 1)) / cols
    readonly property int count: Controls.model.count
    readonly property int rows: Math.ceil(count / cols)

    implicitHeight: rows > 0 ? rows * cell + (rows - 1) * gap : 0

    Repeater {
        model: Controls.model

        delegate: Item {
            id: slot

            required property int index
            required property string tid

            property bool dragging: false
            property real dragX: 0
            property real dragY: 0
            property real grabX: 0
            property real grabY: 0
            readonly property var info: Controls.info(tid)
            readonly property real slotX: (index % root.cols) * (root.cell + root.gap)
            readonly property real slotY: Math.floor(index / root.cols) * (root.cell + root.gap)

            width: root.cell
            height: root.cell
            x: dragging ? dragX : slotX
            y: dragging ? dragY : slotY
            z: dragging ? 10 : 0
            scale: dragging ? 1.08 : (area.pressed && !root.editing ? 0.95 : 1)

            Behavior on x { enabled: !slot.dragging; NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            Behavior on y { enabled: !slot.dragging; NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

            SequentialAnimation on rotation {
                running: root.editing && !slot.dragging
                loops: Animation.Infinite
                NumberAnimation { to: 1.4; duration: 110 }
                NumberAnimation { to: -1.4; duration: 110 }
                onRunningChanged: if (!running) slot.rotation = 0
            }

            Rectangle {
                anchors.fill: parent
                radius: 26
                color: slot.info.active ? Theme.accent : Qt.rgba(1, 1, 1, 0.14)
                Behavior on color { ColorAnimation { duration: 160 } }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 16
                    spacing: 2

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: slot.info.title
                        color: slot.info.active ? "#0b1b33" : Theme.text
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: slot.info.sub
                        color: slot.info.active ? "#2a3f5f" : Theme.dim
                        font.pixelSize: 12
                    }
                }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                preventStealing: true

                onClicked: {
                    if (root.editing)
                        return;
                    Controls.trigger(slot.tid);
                    if (Controls.closesShade(slot.tid))
                        root.closeRequested();
                }
                onPressAndHold: {
                    if (!root.editing)
                        root.editRequested();
                }
                onPressed: mouse => {
                    if (!root.editing)
                        return;
                    slot.grabX = mouse.x;
                    slot.grabY = mouse.y;
                    slot.dragX = slot.slotX;
                    slot.dragY = slot.slotY;
                    slot.dragging = true;
                }
                onPositionChanged: mouse => {
                    if (!slot.dragging)
                        return;
                    const p = mapToItem(root, mouse.x, mouse.y);
                    slot.dragX = p.x - slot.grabX;
                    slot.dragY = p.y - slot.grabY;
                    const col = Math.max(0, Math.min(root.cols - 1, Math.floor(p.x / (root.cell + root.gap))));
                    const row = Math.max(0, Math.min(root.rows - 1, Math.floor(p.y / (root.cell + root.gap))));
                    const target = Math.min(root.count - 1, row * root.cols + col);
                    if (target !== slot.index)
                        Controls.move(slot.index, target);
                }
                onReleased: {
                    if (slot.dragging) {
                        slot.dragging = false;
                        Controls.save();
                    }
                }
                onCanceled: slot.dragging = false
            }

            // Remove badge (edit mode)
            Rectangle {
                visible: root.editing && !slot.dragging
                x: -6
                y: -6
                width: 30
                height: 30
                radius: 15
                color: "#3a3a3c"
                border.color: Qt.rgba(1, 1, 1, 0.3)
                border.width: 1

                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 2
                    radius: 1
                    color: Theme.text
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    onClicked: Controls.remove(slot.index)
                }
            }
        }
    }
}
