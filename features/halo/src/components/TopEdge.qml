import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Invisible strip at the top edge. Dragging down pulls the shade out under the finger
// (UI.shadeDrag follows it 1:1); on release it opens or snaps back depending on distance/speed.
PanelWindow {
    id: root

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 26
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: !UI.shadeOpen

    WlrLayershell.namespace: "halo-edge-top"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    MouseArea {
        id: area
        anchors.fill: parent
        preventStealing: true

        readonly property real dist: 380 // px of travel for a fully open shade
        property real startY: 0
        property real lastY: 0
        property real lastT: 0
        property real vel: 0 // px/ms, + is down

        function gy(m) {
            return mapToItem(null, m.x, m.y).y;
        }

        function finish() {
            const open = UI.shadeDrag > 0.3 || vel > 0.5;
            if (open) {
                UI.homeOpen = false;
                UI.overviewOpen = false;
                UI.shadeOpenedAt = Date.now();
                UI.shadeOpen = true;
            }
            UI.shadeDragging = false;
        }

        onPressed: mouse => {
            startY = gy(mouse);
            lastY = startY;
            lastT = Date.now();
            vel = 0;
            System.refresh();
            UI.shadeDrag = 0;
            UI.shadeDragging = true;
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            const y = gy(mouse);
            UI.shadeDrag = Math.max(0, Math.min(1, (y - startY) / dist));
            const now = Date.now();
            const dt = now - lastT;
            if (dt > 0)
                vel = 0.7 * vel + 0.3 * ((y - lastY) / dt);
            lastY = y;
            lastT = now;
        }
        onReleased: finish()
        onCanceled: finish()
    }
}
