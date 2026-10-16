// =============================================================================
//  DockIcon — one app. Size follows a gaussian of the mouse distance
//  (macOS-style magnification). `mouseX` is relative to the dock window center;
//  `slot` is this icon's nominal (unmagnified) offset from that center.
//    left click  : launch, or focus the first window if running
//    middle click: launch a new instance
//    right click : context menu (actions, windows, tray menu, pin)
//    drag sideways (pinned apps only): reorder
// =============================================================================
import QtQuick
import Quickshell
import qs.config
import qs.services

Item {
    id: ic
    required property var item          // {key, appId, entry, pinned}
    required property real mouseX       // -10000 when the mouse is away
    required property real slot
    signal pinToggled(string appId)
    signal menuRequested(var item, real cx)
    signal reordered(string appId, int newIndex)
    property int idx: 0                 // position in the dock (set by Dock.qml)
    property bool moved: false          // pointer travelled far enough to count as a drag
    property bool dragging: false       // true while the drag is in progress
    property real dragDx: 0
    property real pressSX: 0
    z: dragging ? 100 : 0

    readonly property real base: Config.dock.iconSize
    readonly property real sigma: base * 1.6
    readonly property real mag: 1 + (Config.dock.magnification - 1)
                                 * Math.exp(-Math.pow(mouseX - slot, 2) / (2 * sigma * sigma))
    readonly property var wins: Niri.windowsFor(item.appId)
    readonly property bool running: wins.length > 0
    readonly property bool focused: wins.length > 0 && wins.some(w => w.is_focused)

    // Try the desktop entry's icon, then the app id in a few spellings, then a generic icon.
    readonly property string iconSrc: {
        if (ic.item.launcher) {   // NixOS snowflake from the icon theme, generic fallback
            for (const n of ["nix-snowflake", "nixos", "nix-snowflake-white", "distributor-logo-nixos", "start-here"]) {
                const p = Quickshell.iconPath(n, true);
                if (p) return p;
            }
            return Quickshell.iconPath("application-x-executable");
        }
        const id = ic.item.appId || "";
        const names = [ic.item.entry ? ic.item.entry.icon : "", id, id.toLowerCase(), id.split(".").pop().toLowerCase()];
        for (const n of names) {
            if (!n) continue;
            const p = Quickshell.iconPath(n, true);
            if (p) return p;
        }
        return Quickshell.iconPath("application-x-executable");
    }

    width: base * mag; height: base * mag
    Behavior on width { enabled: ic.mouseX < -5000; NumberAnimation { duration: 140 } }   // smooth only when leaving

    Rectangle {   // hover / focused tile behind the icon
        anchors { fill: parent; margins: -5 }
        radius: Math.min(width, height) * 0.28
        color: ma.containsMouse ? "#26ffffff" : (ic.focused ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22) : "transparent")
        border.width: ma.containsMouse || ic.focused ? 1 : 0
        border.color: ic.focused ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.5) : "#30ffffff"
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    Image {
        id: img
        anchors.fill: parent
        source: ic.iconSrc
        sourceSize: Qt.size(128, 128); smooth: true; mipmap: true
        opacity: ic.dragging ? 0.8 : 1
        transform: [ Translate { id: bounce }, Translate { x: ic.dragging ? ic.dragDx : 0 } ]
    }

    // running indicator
    // one dot per open window (filled = focused); click a dot to focus that window
    Row {
        visible: Config.dock.showRunning
        spacing: 4
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 3 }
        Repeater {
            model: Math.min(ic.wins.length, 6)
            Rectangle {
                required property int index
                readonly property var w: ic.wins[index]
                width: w && w.is_focused ? 14 : 5; height: 4; radius: 2   // focused window = longer pill
                Behavior on width { NumberAnimation { duration: 140 } }
                color: w && w.is_focused ? Theme.primary : Theme.surfaceFg
                opacity: w && w.is_focused ? 1 : 0.5
                MouseArea { anchors { fill: parent; margins: -3 } onClicked: if (parent.w) Niri.focus(parent.w.id) }
            }
        }
    }

    // name tooltip
    Rectangle {
        visible: ma.containsMouse; opacity: visible ? 1 : 0
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.top; bottomMargin: 10 }
        width: tip.implicitWidth + 22; height: 28; radius: 10; color: Theme.surfaceContainerHigh
        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.14)
        Text { id: tip; anchors.centerIn: parent; color: Theme.surfaceFg; font.pixelSize: 12
               text: ic.item.launcher ? "Apps" : (ic.item.entry ? ic.item.entry.name : (ic.item.appId || "")) }
    }

    SequentialAnimation {   // launch bounce
        id: bounceAnim
        NumberAnimation { target: bounce; property: "y"; to: -ic.base * 0.4; duration: 180; easing.type: Easing.OutQuad }
        NumberAnimation { target: bounce; property: "y"; to: 0; duration: 220; easing.type: Easing.OutBounce }
    }

    MouseArea {
        id: ma
        anchors.fill: parent; hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onPressed: mouse => { ic.moved = false; ic.pressSX = ic.mapToItem(null, mouse.x, mouse.y).x }
        onPositionChanged: mouse => {
            if (!pressed || !(pressedButtons & Qt.LeftButton) || !ic.item.pinned) return;
            const dx = ic.mapToItem(null, mouse.x, mouse.y).x - ic.pressSX;
            if (!ic.moved && Math.abs(dx) > 10) ic.moved = true;
            if (ic.moved) { ic.dragging = true; ic.dragDx = dx }
        }
        onReleased: {
            if (!ic.dragging) return;
            const ni = Math.round(ic.idx + ic.dragDx / (ic.base + 10));   // 10 = Row spacing in Dock.qml
            ic.dragging = false; ic.dragDx = 0;
            ic.reordered(ic.item.appId, ni);
        }
        onClicked: mouse => {
            if (ic.moved) { ic.moved = false; return }   // that was a drag, not a click
            if (ic.item.launcher) { if (mouse.button === Qt.LeftButton) { UiState.launcherOpen = !UiState.launcherOpen; bounceAnim.start() } return }
            if (mouse.button === Qt.RightButton) { ic.menuRequested(ic.item, ic.mapToItem(null, ic.width / 2, 0).x); return }
            if (mouse.button === Qt.MiddleButton) { if (ic.item.entry) { ic.item.entry.execute(); bounceAnim.start() } return }
            if (ic.running) {   // cycle: focus the window after the focused one
                let i = ic.wins.findIndex(w => w.is_focused);
                Niri.focus(ic.wins[(i + 1) % ic.wins.length].id);
                return
            }
            if (ic.item.entry) { ic.item.entry.execute(); bounceAnim.start() }
        }
    }
}
