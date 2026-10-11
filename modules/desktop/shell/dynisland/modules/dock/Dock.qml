// =============================================================================
//  Dock — macOS-style floating dock at the bottom.
//  Items = pinned apps (Config.dock.pinned) + any other running apps.
//  Window is wide enough for the magnified size; input is masked to the dock
//  body so the empty area passes clicks through. `autoHide` slides it away.
//
//  TO CHANGE the pinned apps: Settings > Dock, or edit config.json.
// =============================================================================
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    readonly property var cfg: Config.dock

    anchors { bottom: true }
    implicitWidth: Math.max(400, row.baseWidth + cfg.iconSize * 3 + 120)
    implicitHeight: cfg.iconSize * cfg.magnification + 70 + cfg.bottomMargin
    color: "transparent"
    exclusiveZone: cfg.reserveSpace && !cfg.autoHide ? bg.height + cfg.bottomMargin * 2 : 0
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "dynisland-dock"
    mask: Region { item: hit }

    // ---- model: pinned first, then running-but-unpinned ----------------------
    function norm(s) { return (s || "").toLowerCase().replace(/\.desktop$/, "") }
    function togglePin(appId) {
        const cur = Array.from(cfg.pinned);
        const i = cur.findIndex(x => norm(x) === norm(appId));
        if (i >= 0) cur.splice(i, 1); else cur.push(appId);
        cfg.pinned = cur;
    }
    readonly property var items: {
        const out = [];
        for (const id of cfg.pinned)
            out.push({ key: id, appId: id, entry: DesktopEntries.heuristicLookup(id), pinned: true });
        for (const w of Niri.windows) {
            const a = w.app_id;
            if (!a || out.some(o => norm(o.appId) === norm(a))) continue;
            out.push({ key: a, appId: a, entry: DesktopEntries.heuristicLookup(a), pinned: false });
        }
        return out;
    }

    // Is the mouse near the dock? (used by autoHide)
    property bool near: false

    Item {
        id: root
        anchors.fill: parent

        // Mouse x relative to window center. HoverHandler is passive: clicks still reach the icons.
        HoverHandler { id: hh }
        readonly property real mouseX: hh.hovered ? hh.point.position.x - width / 2 : -10000

        // hit area for the input mask (dock body, or a thin strip when hidden)
        Item {
            id: hit
            x: bg.x - 10; width: bg.width + 20
            height: win.cfg.autoHide && !hh.hovered ? 6 : parent.height
            anchors.bottom: parent.bottom
        }

        Rectangle {
            id: bg
            readonly property bool hidden: win.cfg.autoHide && !hh.hovered
            anchors.horizontalCenter: parent.horizontalCenter
            y: hidden ? parent.height + 20 : parent.height - height - win.cfg.bottomMargin
            Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

            width: row.width + 28
            height: win.cfg.iconSize + 22
            radius: 24
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.62)
            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.14)

            Row {
                id: row
                spacing: 10
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 11 }
                readonly property real baseWidth: win.items.length * (win.cfg.iconSize + spacing)
                Repeater {
                    model: win.items
                    DockIcon {
                        required property int index
                        // nominal offset of this icon from the dock center (unmagnified layout)
                        slot: (index - (win.items.length - 1) / 2) * (win.cfg.iconSize + row.spacing)
                        mouseX: root.mouseX
                        item: modelData
                        onPinToggled: id => win.togglePin(id)
                    }
                }
            }
        }
    }
}
