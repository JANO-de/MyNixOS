import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

AppWindow {
    id: root
    title: "Gallery"
    heading: viewing ? (cur + 1) + " / " + shown.length : "Gallery"
    canBack: viewing
    onBackClicked: viewing = false

    readonly property string pics: AppTheme.home + "/Pictures"
    property var all: []          // { path, album, mtime } newest first
    property string album: ""     // "" = all
    property bool viewing: false
    property int cur: 0
    readonly property var shown: album === "" ? all : all.filter(p => p.album === album)
    readonly property var albums: {
        const s = {};
        for (const p of all)
            if (p.album !== "")
                s[p.album] = true;
        return Object.keys(s).sort();
    }

    function rescan() {
        scan.running = false;
        scan.running = true;
    }
    function parse(t) {
        const out = [];
        for (const l of t.split("\n")) {
            const i = l.indexOf("\t");
            if (i < 0)
                continue;
            const p = l.substring(i + 1);
            const rel = p.substring(pics.length + 1);
            out.push({ path: p, mtime: parseFloat(l.substring(0, i)), album: rel.indexOf("/") > 0 ? rel.substring(0, rel.indexOf("/")) : "" });
        }
        out.sort((a, b) => b.mtime - a.mtime);
        all = out;
    }
    function trashCurrent() {
        if (cur < 0 || cur >= shown.length)
            return;
        const p = shown[cur].path;
        const last = shown.length === 1;
        op.command = ["sh", "-c", "gio trash -- \"$1\" 2>/dev/null || rm -f -- \"$1\"", "sh", p];
        op.running = false;
        op.running = true;
        if (last)
            viewing = false;
    }

    Process {
        id: scan
        command: ["find", "-L", root.pics, "-maxdepth", "4", "-type", "f", "(", "-iname", "*.png", "-o", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.webp", "-o", "-iname", "*.gif", ")", "-printf", "%T@\t%p\n"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Process {
        id: op
        onExited: root.rescan()
    }
    Component.onCompleted: rescan()

    actions: [
        Pill { visible: root.viewing; label: "Delete"; danger: true; onClicked: root.trashCurrent() }
    ]

    // Album chips
    Flickable {
        id: chips
        visible: !root.viewing
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        height: 52
        contentWidth: chipRow.width
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Row {
            id: chipRow
            spacing: 8
            Pill { label: "All"; on: root.album === ""; onClicked: root.album = "" }
            Repeater {
                model: root.albums
                Pill {
                    required property string modelData
                    label: modelData
                    on: root.album === modelData
                    onClicked: root.album = modelData
                }
            }
        }
    }

    GridView {
        id: grid
        visible: !root.viewing
        anchors.top: chips.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        readonly property int cols: Math.max(2, Math.floor(width / 190))
        cellWidth: Math.floor(width / cols)
        cellHeight: cellWidth
        clip: true
        model: root.shown
        boundsBehavior: Flickable.StopAtBounds
        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            width: grid.cellWidth
            height: grid.cellHeight
            Image {
                anchors.fill: parent
                anchors.margins: 3
                source: "file://" + cell.modelData.path
                sourceSize: Qt.size(320, 320)
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.cur = cell.index;
                    root.viewing = true;
                    pager.positionViewAtIndex(cell.index, ListView.Beginning);
                }
            }
        }
        Text {
            visible: root.shown.length === 0
            anchors.centerIn: parent
            text: "No photos in ~/Pictures"
            color: AppTheme.dim
            font.pixelSize: 18
        }
    }

    // Full-screen viewer: swipe between photos, pinch to zoom, double-tap toggles zoom.
    ListView {
        id: pager
        visible: root.viewing
        anchors.fill: parent
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        interactive: !zoomed
        property bool zoomed: false
        cacheBuffer: width
        model: root.viewing ? root.shown : []
        boundsBehavior: Flickable.StopAtBounds
        onCurrentIndexChanged: if (root.viewing) root.cur = currentIndex
        onVisibleChanged: if (visible) currentIndex = root.cur

        delegate: Item {
            id: page
            required property var modelData
            width: pager.width
            height: pager.height
            clip: true

            Image {
                id: img
                width: page.width
                height: page.height
                source: "file://" + page.modelData.path
                sourceSize: Qt.size(2400, 2400)
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                onScaleChanged: {
                    if (ListView.isCurrentItem)
                        pager.zoomed = scale > 1.02;
                    if (scale <= 1.02) {
                        x = 0;
                        y = 0;
                    }
                }
            }
            PinchHandler {
                target: img
                minimumScale: 1
                maximumScale: 6
                minimumRotation: 0
                maximumRotation: 0
            }
            DragHandler {
                target: img
                enabled: img.scale > 1.02
            }
            TapHandler {
                acceptedButtons: Qt.LeftButton
                onDoubleTapped: img.scale = img.scale > 1.02 ? 1 : 2.5
            }
        }
    }
}
