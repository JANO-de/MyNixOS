import QtQuick
import Quickshell
import qs.services

// Folder contents, ported from Launcher3 FolderPagedView: grid = ceil(sqrt(count)) columns (max 4), rows as needed
// (max 4), so 16 items per page; swipe between pages, page dots when there is more than one page.
// Items are LibItems: tap = open, long-press then drag = reorder here or take the app out (window-global coordinates).
Item {
    id: root

    property string fid: ""
    property bool dragging: false
    property int dropRank: -1
    property int hot: 0 // -1 / 1 while a drag hovers the left / right edge (flips pages, like FolderAutoScrollHelper)
    signal itemActivated(var entry)
    signal itemDragBegan(var entry, real gx, real gy)
    signal itemDragMoved(real gx, real gy)
    signal itemDragEnded(real gx, real gy)

    readonly property var items: Home.folders[fid] ? Home.folders[fid].items : []
    readonly property int count: items.length
    readonly property int maxX: 4
    readonly property int maxY: 4
    readonly property int perPage: maxX * maxY
    readonly property int cx: Math.max(1, Math.min(maxX, Math.ceil(Math.sqrt(Math.max(1, count)))))
    readonly property int cy: Math.max(1, Math.min(maxY, Math.ceil(Math.max(1, count) / cx)))
    readonly property int pages: Math.max(1, Math.ceil(count / perPage))
    readonly property int cellW: 104
    readonly property int cellH: 124

    width: cx * cellW
    height: cy * cellH + (pages > 1 ? 30 : 0)

    function rankAt(gx, gy) {
        const p = list.mapFromItem(null, gx, gy);
        const col = Math.max(0, Math.min(cx - 1, Math.floor(p.x / cellW)));
        const row = Math.max(0, Math.min(cy - 1, Math.floor(p.y / cellH)));
        return Math.max(0, Math.min(count - 1, list.currentIndex * perPage + row * cx + col));
    }

    // Called while a drag from this folder is in progress.
    function dragAt(gx, gy, inside) {
        dragging = true;
        dropRank = inside ? rankAt(gx, gy) : -1;
        const p = list.mapFromItem(null, gx, gy);
        hot = (!inside || pages < 2) ? 0 : (p.x < 24 ? -1 : (p.x > list.width - 24 ? 1 : 0));
    }

    function dragDone() {
        dragging = false;
        dropRank = -1;
        hot = 0;
    }

    Timer {
        interval: 600
        repeat: true
        running: root.hot !== 0
        onTriggered: list.currentIndex = Math.max(0, Math.min(root.pages - 1, list.currentIndex + root.hot))
    }

    ListView {
        id: list
        width: root.cx * root.cellW
        height: root.cy * root.cellH
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: 220
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        interactive: root.pages > 1
        model: root.pages

        delegate: Item {
            id: pg
            required property int index
            width: list.width
            height: list.height

            // Drop marker (accent ring) on the slot a dragged app will take.
            Rectangle {
                readonly property int k: root.dropRank - pg.index * root.perPage
                visible: root.dragging && k >= 0 && k < root.perPage
                x: (k % root.cx) * root.cellW + 6
                y: Math.floor(k / root.cx) * root.cellH + 6
                width: root.cellW - 12
                height: root.cellH - 12
                radius: 22
                color: Qt.rgba(1, 1, 1, 0.12)
                border.color: Theme.accent
                border.width: 2
            }

            Repeater {
                model: root.items.slice(pg.index * root.perPage, (pg.index + 1) * root.perPage)

                LibItem {
                    id: it
                    required property int index
                    required property string modelData
                    readonly property var e: DesktopEntries.byId(modelData)

                    x: (index % root.cx) * root.cellW
                    y: Math.floor(index / root.cx) * root.cellH
                    width: root.cellW
                    height: root.cellH
                    entry: e
                    onActivated: if (e) root.itemActivated(e)
                    onDragBegan: (gx, gy) => { if (e) root.itemDragBegan(e, gx, gy); }
                    onDragMoved: (gx, gy) => root.itemDragMoved(gx, gy)
                    onDragEnded: (gx, gy) => root.itemDragEnded(gx, gy)
                }
            }
        }
    }

    // Page dots (Launcher3 PageIndicatorDots), only when there is more than one page.
    Row {
        visible: root.pages > 1
        anchors.horizontalCenter: parent.horizontalCenter
        y: list.height + 10
        spacing: 9

        Repeater {
            model: root.pages

            Rectangle {
                required property int index
                width: 8
                height: 8
                radius: 4
                color: Theme.text
                opacity: index === list.currentIndex ? 0.95 : 0.35
                scale: index === list.currentIndex ? 1.2 : 1
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 160 } }
            }
        }
    }
}
