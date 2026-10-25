import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Back gesture: swipe in from the left or right screen edge (Android EdgeBackGestureHandler idea).
// An arrow bubble follows the finger; releasing past `trigger` px calls UI.back().
// The window is wide enough for the bubble, but only the thin strip takes input (mask).
PanelWindow {
    id: root

    property bool leftSide: true
    readonly property real trigger: 72
    readonly property real stripW: 22

    anchors.top: true
    anchors.bottom: true
    anchors.left: leftSide
    anchors.right: !leftSide
    margins.top: 44
    margins.bottom: 84
    implicitWidth: 150
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: strip }

    WlrLayershell.namespace: "halo-edge-back"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Item {
        id: strip
        x: root.leftSide ? 0 : root.width - root.stripW
        y: 0
        width: root.stripW
        height: root.height

        MouseArea {
            id: ma
            anchors.fill: parent
            preventStealing: true
            property real startX: 0
            property real startY: 0
            property real dx: 0
            property real dy: 0
            property real fy: 0

            function gp(m) { return mapToItem(null, m.x, m.y); }

            onPressed: m => {
                const g = gp(m);
                startX = g.x;
                startY = g.y;
                fy = g.y;
                dx = 0;
                dy = 0;
            }
            onPositionChanged: m => {
                if (!pressed)
                    return;
                const g = gp(m);
                dx = root.leftSide ? g.x - startX : startX - g.x;
                dy = g.y - startY;
                fy = g.y;
            }
            onReleased: {
                if (dx >= root.trigger && Math.abs(dy) < dx * 1.5)
                    UI.back();
                dx = 0;
            }
            onCanceled: dx = 0
        }
    }

    // Arrow bubble: slides in with the finger, turns accent colour once the swipe is long enough.
    Rectangle {
        readonly property real prog: Math.max(0, Math.min(1, ma.dx / root.trigger))
        readonly property bool armed: ma.dx >= root.trigger
        width: 48
        height: 48
        radius: 24
        visible: ma.pressed && ma.dx > 4
        y: ma.fy - 44 - 24
        x: root.leftSide ? -48 + prog * 92 : root.width - 44 - prog * 92
        color: armed ? Theme.accent : Theme.surfaceHigh
        border.color: Theme.glassStroke
        border.width: 1
        scale: armed ? 1.12 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }

        Text {
            anchors.centerIn: parent
            text: root.leftSide ? "\u2039" : "\u203a"
            color: parent.armed ? Theme.accentInk : Theme.text
            font.pixelSize: 34
        }
    }
}
