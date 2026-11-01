import QtQuick
import qs.common

// Date-sectioned photo grid. Rows (header rows + tile rows) feed one ListView; pinch / Ctrl+wheel changes the column count.
Item {
    id: g
    property var host
    readonly property int cols: host.cols
    readonly property real pad: 10
    readonly property real gap: 4
    readonly property real cell: Math.max(40, Math.floor((width - 2 * pad - (cols - 1) * gap) / cols))
    readonly property var rows: build(host.shown, cols, host.group)
    property string sticky: ""

    function build(list, n, grp) {
        const out = [];
        let key = null;
        let row = null;
        let head = null;
        for (let i = 0; i < list.length; i++) {
            const sec = grp === "all" ? "" : host.secLabel(list[i].mtime);
            if (sec !== key) {
                key = sec;
                row = null;
                head = null;
                if (sec !== "") {
                    head = { kind: "h", sec: sec, paths: [] };
                    out.push(head);
                }
            }
            if (row === null || row.items.length >= n) {
                row = { kind: "r", sec: sec, items: [] };
                out.push(row);
            }
            row.items.push({ i: i, e: list[i] });
            if (head)
                head.paths.push(list[i].path);
        }
        return out;
    }
    function updateSticky() {
        const i = lv.indexAt(20, lv.contentY + 20);
        sticky = (i >= 0 && i < rows.length && rows[i].kind === "r") ? rows[i].sec : "";
    }

    ListView {
        id: lv
        anchors.fill: parent
        clip: true
        model: g.rows
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 600
        onContentYChanged: g.updateSticky()

        delegate: Item {
            id: rw
            required property var modelData
            readonly property bool hdr: modelData.kind === "h"
            width: lv.width
            height: hdr ? 54 : g.cell + g.gap

            // section header
            Item {
                visible: rw.hdr
                anchors.fill: parent
                Text {
                    x: g.pad + 4
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 4
                    text: rw.hdr ? rw.modelData.sec : ""
                    color: AppTheme.text
                    font.pixelSize: 19
                    font.weight: Font.DemiBold
                }
                Rectangle {
                    visible: g.host.selMode
                    anchors.right: parent.right
                    anchors.rightMargin: g.pad
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 4
                    width: selTxt.implicitWidth + 24
                    height: 32
                    radius: 16
                    color: hm.pressed ? AppTheme.cardHigh : AppTheme.card
                    Text { id: selTxt; anchors.centerIn: parent; text: "Select"; color: AppTheme.accent; font.pixelSize: 14; font.weight: Font.DemiBold }
                    MouseArea { id: hm; anchors.fill: parent; onClicked: g.host.selectMany(rw.modelData.paths) }
                }
            }

            // tile row
            Row {
                visible: !rw.hdr
                x: g.pad
                spacing: g.gap
                Repeater {
                    model: rw.hdr ? [] : rw.modelData.items
                    Item {
                        id: tile
                        required property var modelData
                        readonly property var e: modelData.e
                        readonly property bool picked: g.host.sel[e.path] === true
                        property bool held: false
                        width: g.cell
                        height: g.cell

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: AppTheme.card
                        }
                        Item {
                            anchors.fill: parent
                            scale: tile.picked ? 0.86 : 1
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            RoundImg {
                                anchors.fill: parent
                                radius: tile.picked ? 16 : 12
                                px: Math.max(160, g.cell * 2)
                                source: g.host.srcOf(tile.e)
                            }
                            Ico {
                                visible: tile.e.video
                                anchors.centerIn: parent
                                name: "video"
                                size: g.cell * 0.3
                                color: AppTheme.dim
                                z: -1
                            }
                            // video badge
                            Rectangle {
                                visible: tile.e.video
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 6
                                width: 30
                                height: 22
                                radius: 11
                                color: Qt.rgba(0, 0, 0, 0.55)
                                Ico { anchors.centerIn: parent; name: "play"; filled: true; size: 12; color: "#ffffff" }
                            }
                            // favourite badge
                            Ico {
                                visible: g.host.favs[tile.e.path] === true
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                                anchors.margins: 6
                                name: "heart"
                                filled: true
                                size: 18
                                color: "#ffffff"
                            }
                        }
                        // selection ring
                        Rectangle {
                            visible: g.host.selMode
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.margins: 8
                            width: 26
                            height: 26
                            radius: 13
                            color: tile.picked ? AppTheme.accent : Qt.rgba(0, 0, 0, 0.35)
                            border.width: 2
                            border.color: tile.picked ? AppTheme.accent : "#ffffff"
                            Ico { visible: tile.picked; anchors.centerIn: parent; name: "check"; size: 16; color: AppTheme.accentInk }
                        }
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onPressed: tile.held = false
                            onClicked: mouse => {
                                if (tile.held) {
                                    tile.held = false;
                                    return;
                                }
                                if (mouse.button === Qt.RightButton) {
                                    const ps = g.host.sel[tile.e.path] ? g.host.selPaths() : [tile.e.path];
                                    g.host.itemMenu(tile, mouse.x, mouse.y, ps);
                                } else {
                                    g.host.tileTap(tile.modelData.i);
                                }
                            }
                        }
                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            gesturePolicy: TapHandler.WithinBounds
                            longPressThreshold: 0.5
                            onLongPressed: {
                                tile.held = true;
                                if (g.host.selMode) {
                                    const ps = g.host.sel[tile.e.path] ? g.host.selPaths() : [tile.e.path];
                                    g.host.itemMenu(tile, point.position.x, point.position.y, ps);
                                } else {
                                    g.host.tileHold(tile.modelData.i);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // sticky section label
    Rectangle {
        visible: g.sticky !== "" && lv.contentY > 10
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: g.pad
        anchors.topMargin: 6
        height: 32
        width: stickyTxt.implicitWidth + 28
        radius: 16
        color: Qt.rgba(AppTheme.bg.r, AppTheme.bg.g, AppTheme.bg.b, 0.82)
        Text { id: stickyTxt; anchors.centerIn: parent; text: g.sticky; color: AppTheme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
    }

    PinchHandler {
        target: null
        onActiveChanged: {
            if (!active) {
                if (activeScale > 1.2)
                    g.host.setCols(g.host.cols - 1);
                else if (activeScale < 0.8)
                    g.host.setCols(g.host.cols + 1);
            }
        }
    }
    WheelHandler {
        acceptedModifiers: Qt.ControlModifier
        onWheel: event => g.host.setCols(g.host.cols + (event.angleDelta.y > 0 ? -1 : 1))
    }
}
