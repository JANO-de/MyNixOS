import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Android split-screen divider: a handle between the two apps. Drag it; on release it snaps to
// 30/70, 50/50 or 70/30. Dragging it into an edge zone dismisses that app (the other fills the screen).
// Full-screen transparent overlay whose input region is only the divider strip.
PanelWindow {
    id: root

    // Does not read `screen` (that made a binding loop with `visible`).
    readonly property bool shown: {
        if (!Tiling.splitVisible)
            return false;
        for (const s of Quickshell.screens)
            if (Math.round(s.width) === Math.round(Tiling.splitW))
                return true;
        return false;
    }
    readonly property real committedX: Tiling.boundaryX(Tiling.ratio)

    property bool dragging: false
    property real dragX: 0

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    visible: shown
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: hit }

    WlrLayershell.namespace: "halo-splitdivider"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    function snapTo(x) {
        const r = (x - Tiling.gapOut) / (Tiling.splitW - 2 * Tiling.gapOut);
        console.log("halo-split snap x=" + Math.round(x) + " r=" + r.toFixed(2));
        if (r < 0.15) {
            Tiling.dismiss("left");
            return;
        }
        if (r > 0.85) {
            Tiling.dismiss("right");
            return;
        }
        const targets = [0.3, 0.5, 0.7];
        let best = 0.5;
        for (const t of targets)
            if (Math.abs(t - r) < Math.abs(best - r))
                best = t;
        Tiling.applyRatio(best);
    }

    // Dismiss hint while the handle sits in an edge zone.
    Rectangle {
        visible: root.dragging
        x: 0
        width: Math.max(0, Math.min(root.dragX, root.width * 0.15))
        height: parent.height
        color: Qt.rgba(0, 0, 0, 0.45)
    }
    Rectangle {
        visible: root.dragging
        x: Math.max(root.dragX, root.width * 0.85)
        width: Math.max(0, root.width - x)
        height: parent.height
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    // Touch strip (not moved while dragging, so the finger position stays stable).
    Item {
        id: hit
        x: root.committedX - 28
        width: 56
        height: parent.height

        MouseArea {
            anchors.fill: parent
            preventStealing: true
            onPressed: m => {
                root.dragX = hit.x + m.x;
                root.dragging = true;
            }
            onPositionChanged: m => {
                if (root.dragging)
                    root.dragX = Math.max(0, Math.min(root.width, hit.x + m.x));
            }
            onReleased: {
                root.dragging = false;
                root.snapTo(root.dragX);
            }
            onCanceled: root.dragging = false
        }
    }

    // The handle (Android: a slim pill that grows while touched).
    Rectangle {
        id: pill
        x: (root.dragging ? root.dragX : root.committedX) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: root.dragging ? 10 : 6
        height: root.dragging ? 112 : 56
        radius: width / 2
        color: root.dragging ? Theme.accent : Qt.rgba(1, 1, 1, 0.75)
        Behavior on x { enabled: !root.dragging; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 120 } }
        Behavior on height { NumberAnimation { duration: 120 } }
    }
}
