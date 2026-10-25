import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Invisible strip at the bottom edge: the iPadOS home gesture, one continuous finger-tracked swipe.
//   inside an app:
//     short swipe up, release      -> the dock slides up over the app (stays 5 s)
//     flick up                     -> home screen
//     keep going and pause         -> app switcher (overview)
//     keep going, still moving     -> home screen (projected end point past half the screen)
//     swipe sideways along the edge-> previous / next app (right = the one used before)
//   on the home screen:  pause -> app switcher; flick or far swipe -> app launcher (SUPER+A overlay)
//   with the launcher open: flick or far swipe -> back to the home screen; pause -> app switcher
// Tunables: dockZone, appear, homeAt, flickSpeed, projectMs, sideMin.
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
        readonly property real dockZone: 110 // px of drag that pull the dock fully up (in an app)
        readonly property real appear: screenH * 0.25 // overview fully visible this far past the dock zone
        readonly property real homeAt: screenH * 0.5 // projected end past this = home / launcher
        readonly property real flickSpeed: 1.5 // px/ms upward: a fling
        readonly property real projectMs: 200 // momentum projection (Apple ~500 ms, damped)
        readonly property real sideMin: 70 // px sideways to switch app (or a quick sideways flick)
        property real startX: 0
        property real startY: 0
        property real dist: 0
        property real dx: 0
        property string mode: "" // "" undecided, "up", "side"
        property var samples: [] // {t, x, y} of the last ~100 ms

        // Swipe stages depend on where we started.
        readonly property bool launcher: UI.homeOpen
        readonly property bool inApp: !UI.onHome && !UI.homeOpen
        readonly property bool dockStage: UI.appOpen && !UI.homeOpen

        function gp(m) {
            return mapToItem(null, m.x, m.y);
        }

        function window100() {
            const now = Date.now();
            return samples.filter(p => now - p.t <= 100);
        }

        // Upward speed over the last 100 ms (px/ms); 0 if the finger rested before lifting.
        function speed() {
            const s = window100();
            if (s.length < 2)
                return 0;
            const a = s[0];
            const b = s[s.length - 1];
            const dt = b.t - a.t;
            return dt > 0 ? (a.y - b.y) / dt : 0;
        }

        function speedX() {
            const s = window100();
            if (s.length < 2)
                return 0;
            const a = s[0];
            const b = s[s.length - 1];
            const dt = b.t - a.t;
            return dt > 0 ? (b.x - a.x) / dt : 0;
        }

        // Where the finger would come to rest (iOS-style projection; no momentum if it paused).
        function projected() {
            return dist + Math.max(0, speed()) * projectMs;
        }

        function track() {
            if (dockStage) {
                UI.dockDragging = true;
                UI.dockPeek = Math.min(1, dist / dockZone);
                const over = Math.max(0, dist - dockZone);
                UI.overviewDrag = Math.min(1, over / appear);
                UI.overviewDragging = over > 0;
            } else {
                UI.overviewDrag = Math.min(1, dist / appear);
                UI.overviewDragging = true;
            }
            UI.overviewHomeHint = UI.overviewDragging && (projected() > homeAt || speed() > flickSpeed);
        }

        function finish() {
            const m = mode;
            const v = speed();
            const end = projected();
            const wasDockStage = dockStage;
            mode = "";
            UI.overviewDragging = false;
            UI.overviewHomeHint = false;
            UI.dockDragging = false;
            UI.dockPeek = 0;

            if (m === "side") {
                if (Math.abs(dx) > sideMin || Math.abs(speedX()) > 0.8)
                    UI.quickSwitch(dx > 0 ? 1 : -1);
                return;
            }
            if (m === "" || (dist < 40 && v < flickSpeed))
                return; // a tap or a tiny drag

            if (launcher) {
                if (v > flickSpeed || end > homeAt)
                    UI.goHome();
                else
                    UI.openOverview();
            } else if (!inApp) {
                if (v > flickSpeed || end > homeAt)
                    UI.openHome();
                else
                    UI.openOverview();
            } else if (v > flickSpeed) {
                UI.goHome();
            } else if (wasDockStage && dist <= dockZone * 1.15) {
                UI.pinDock();
            } else if (end > homeAt) {
                UI.goHome();
            } else {
                UI.openOverview();
            }
        }

        onPressed: mouse => {
            const g = gp(mouse);
            startX = g.x;
            startY = g.y;
            dist = 0;
            dx = 0;
            mode = "";
            samples = [{ t: Date.now(), x: g.x, y: g.y }];
            UI.overviewDrag = 0;
            UI.overviewHomeHint = false;
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            const g = gp(mouse);
            dx = g.x - startX;
            dist = Math.max(0, startY - g.y);
            const keep = window100();
            keep.push({ t: Date.now(), x: g.x, y: g.y });
            samples = keep;

            if (mode === "") {
                const adx = Math.abs(dx);
                if (Math.max(adx, dist) < 14)
                    return;
                mode = (adx > dist * 1.2 && inApp) ? "side" : "up";
            }
            if (mode === "up")
                track();
        }
        onReleased: finish()
        onCanceled: finish()
    }
}
