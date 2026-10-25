import QtQuick
import Quickshell
import qs.services

// Chooser for the pencil in edit mode: photos (many), sticker (one image or glyph), app (one) / apps (up to 4).
Item {
    id: root

    signal done

    readonly property var inst: Home.winstById(Home.pickFor)
    readonly property var type: inst ? Home.typeOf(inst.type) : null
    readonly property string mode: type && type.pick ? type.pick : ""
    readonly property int maxSel: mode === "photos" ? 20 : (mode === "apps" ? 4 : 1)
    property var sel: []

    readonly property var items: {
        if (mode === "photos")
            return Pics.files.map(p => ({ key: p, kind: "img", name: "" }));
        if (mode === "sticker")
            return Pics.stickerGlyphs.map(g => ({ key: g, kind: "glyph", name: "" })).concat(Pics.files.map(p => ({ key: p, kind: "img", name: "" })));
        if (mode === "app" || mode === "apps") {
            const l = DesktopEntries.applications.values.slice();
            l.sort((a, b) => String(a.name).localeCompare(String(b.name)));
            return l.map(e => ({ key: e.id, kind: "app", name: e.name, icon: e.icon }));
        }
        return [];
    }

    onInstChanged: {
        if (!inst || !inst.cfg) {
            sel = [];
            return;
        }
        const c = inst.cfg;
        if (mode === "photos")
            sel = (c.photos || []).slice();
        else if (mode === "sticker")
            sel = c.src ? [c.src] : (c.glyph ? [c.glyph] : []);
        else
            sel = (c.apps || []).slice();
    }

    function toggle(k) {
        const i = sel.indexOf(k);
        if (i >= 0) {
            sel = sel.filter(x => x !== k);
        } else if (maxSel === 1) {
            sel = [k];
        } else if (sel.length < maxSel) {
            sel = sel.concat([k]);
        }
    }

    function save() {
        if (!inst)
            return;
        if (mode === "photos")
            Home.setCfg(inst.id, { photos: sel });
        else if (mode === "sticker")
            Home.setCfg(inst.id, sel.length === 0 ? {} : (sel[0].charAt(0) === "/" ? { src: sel[0] } : { glyph: sel[0] }));
        else
            Home.setCfg(inst.id, { apps: sel });
        done();
    }

    Component.onCompleted: Pics.rescan()

    Rectangle {
        id: bar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        color: "transparent"

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.mode === "photos" ? "Pick photos (" + root.sel.length + ")"
                : root.mode === "sticker" ? "Pick a sticker or a picture"
                : root.mode === "app" ? "Pick an app" : "Pick up to 4 apps (" + root.sel.length + ")"
            color: Theme.dim
            font.pixelSize: 14
        }
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 84
            height: 34
            radius: 17
            color: Theme.accent
            Text {
                anchors.centerIn: parent
                text: "Done"
                color: Theme.accentInk
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            MouseArea { anchors.fill: parent; onClicked: root.save() }
        }
    }

    GridView {
        anchors.top: bar.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        cellWidth: root.mode === "app" || root.mode === "apps" ? 96 : 110
        cellHeight: cellWidth
        model: root.items
        boundsBehavior: Flickable.StopAtBounds

        delegate: Item {
            id: cell
            required property var modelData
            readonly property bool on: root.sel.indexOf(modelData.key) >= 0
            width: GridView.view.cellWidth
            height: GridView.view.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 16
                color: Qt.rgba(1, 1, 1, 0.08)
                border.color: cell.on ? Theme.accent : "transparent"
                border.width: 3
                clip: true

                Image {
                    anchors.fill: parent
                    visible: cell.modelData.kind === "img"
                    source: cell.modelData.kind === "img" ? "file://" + cell.modelData.key : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 200
                    sourceSize.height: 200
                }
                Text {
                    anchors.centerIn: parent
                    visible: cell.modelData.kind === "glyph"
                    text: cell.modelData.kind === "glyph" ? cell.modelData.key : ""
                    color: Theme.accent
                    font.pixelSize: 40
                }
                Column {
                    anchors.centerIn: parent
                    visible: cell.modelData.kind === "app"
                    spacing: 3
                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 48
                        height: 48
                        source: cell.modelData.kind === "app" ? Apps.iconSource(cell.modelData.icon) : ""
                        sourceSize: Qt.size(96, 96)
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        width: cell.width - 16
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: cell.modelData.name
                        color: Theme.text
                        font.pixelSize: 11
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.toggle(cell.modelData.key)
            }
        }
    }
}
