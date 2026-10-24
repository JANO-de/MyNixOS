import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Invisible strip at the bottom edge. Swipe up, modeled on Android Quickstep / iPadOS:
//   on the home screen : any drag opens the overview
//   inside an app      : slow release -> overview, past half the screen -> home,
//                        fast fling up -> home, tiny drag -> nothing
// The overview fades in under the finger; past the half-way mark it dims to show "release = home".
PanelWindow {
    id: root

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 32
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    // Hidden while the overview is open (it handles touches) and while the keyboard is up.
    visible: !UI.overviewOpen && !Kbd.visible

    WlrLayershell.namespace: "halo-edge-bottom"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    MouseArea {
        id: area
        anchors.fill: parent
        preventStealing: true

        readonly property real screenH: root.screen ? root.screen.height : 1000
        readonly property real appear: screenH * 0.25 // overview fully visible at this drag distance
        readonly property real homeAt: screenH * 0.5 // beyond this (in an app) release = home
        readonly property real flickSpeed: 1.5 // px/ms upward, like Quickstep's fling threshold
        property real startY: 0
        property real dist: 0
        property var samples: [] // {t, y} of the last ~100 ms

        function gy(m) {
            return mapToItem(null, m.x, m.y).y;
        }

        // Upward speed over the last 100 ms; 0 if the finger rested before lifting.
        function speed() {
            const now = Date.now();
            const s = samples.filter(p => now - p.t <= 100);
            if (s.length < 2)
                return 0;
            const a = s[0];
            const b = s[s.length - 1];
            const dt = b.t - a.t;
            return dt > 0 ? (a.y - b.y) / dt : 0;
        }

        function finish() {
            const v = speed();
            const onHome = UI.onHome;
            UI.overviewDragging = false;
            UI.overviewHomeHint = false;
            if (dist < 40 && v < flickSpeed)
                return; // a tap or a tiny drag
            if (onHome)
                UI.openOverview();
            else if (v > flickSpeed || dist > homeAt)
                UI.goHome();
            else
                UI.openOverview();
        }

        onPressed: mouse => {
            startY = gy(mouse);
            dist = 0;
            samples = [{ t: Date.now(), y: startY }];
            UI.overviewDrag = 0;
            UI.overviewHomeHint = false;
            UI.overviewDragging = true;
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            const y = gy(mouse);
            dist = Math.max(0, startY - y);
            UI.overviewDrag = Math.min(1, dist / appear);
            UI.overviewHomeHint = !UI.onHome && dist > homeAt;
            const now = Date.now();
            const keep = samples.filter(p => now - p.t <= 100);
            keep.push({ t: now, y: y });
            samples = keep;
        }
        onReleased: finish()
        onCanceled: finish()
    }
}
