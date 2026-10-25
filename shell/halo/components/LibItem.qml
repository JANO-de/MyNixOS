import QtQuick
import qs.services

// App Library icon: tap = open, long-press then drag = add to home / pin to dock (coordinates are window-global).
Item {
    id: root

    property var entry: null
    signal activated
    signal dragBegan(real gx, real gy)
    signal dragMoved(real gx, real gy)
    signal dragEnded(real gx, real gy)

    AppIcon {
        anchors.fill: parent
        entry: root.entry
        interactive: false
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        property bool held: false
        property real lgx: 0
        property real lgy: 0

        function endDrag() {
            if (held)
                root.dragEnded(lgx, lgy);
            held = false;
            preventStealing = false;
        }

        onClicked: root.activated()
        onPressAndHold: {
            held = true;
            preventStealing = true;
            const g = mapToItem(null, mouseX, mouseY);
            lgx = g.x;
            lgy = g.y;
            root.dragBegan(lgx, lgy);
        }
        onPositionChanged: m => {
            if (!held)
                return;
            const g = mapToItem(null, m.x, m.y);
            lgx = g.x;
            lgy = g.y;
            root.dragMoved(lgx, lgy);
        }
        onReleased: endDrag()
        onCanceled: endDrag()
    }
}
