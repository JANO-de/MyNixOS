import QtQuick
import qs.services

// One placed widget: glass card (unless bare), free drag / resize in edit mode, "-" remove, pencil configure.
// Placement comes from `inst` ({ id, type, page, fx, fy, w, h, cfg }); in the gallery set `preview: true`.
Item {
    id: root

    property var inst: null
    property bool preview: false
    // Geometry of the page this widget sits on (set by Desktop).
    property real unit: 150
    property real gap: 16
    property real pw: 1000
    property real ph: 600
    property real xPad: 0
    property Item pagerItem: null
    property Flickable flickRef: null
    property int maxPage: 0
    signal configure
    signal wantPage(int page)

    readonly property var type: inst ? Home.typeOf(inst.type) : null
    readonly property bool bare: type ? !!type.bare : false
    readonly property bool fullBleed: type ? !!type.edge : false
    readonly property bool canEdit: Home.editing && !preview

    // Live values while dragging / resizing.
    property bool dragging: false
    property bool resizing: false
    property real dx: 0
    property real dy: 0
    property real lw: 1
    property real lh: 1
    readonly property real uw: resizing ? lw : (inst ? inst.w : 1)
    readonly property real uh: resizing ? lh : (inst ? inst.h : 1)

    function sizeFor(u) { return u * unit + (u - 1) * gap; }

    // Placed widgets are positioned/sized from `inst`; previews are sized by their parent.
    Binding { target: root; property: "width"; value: root.sizeFor(root.uw); when: !root.preview; restoreMode: Binding.RestoreNone }
    Binding { target: root; property: "height"; value: root.sizeFor(root.uh); when: !root.preview; restoreMode: Binding.RestoreNone }
    Binding { target: root; property: "x"; value: root.dragging ? root.dx : (root.inst ? root.inst.page * root.pw + root.inst.fx * root.pw : 0); when: !root.preview; restoreMode: Binding.RestoreNone }
    Binding { target: root; property: "y"; value: root.dragging ? root.dy : (root.inst ? root.inst.fy * root.ph : 0); when: !root.preview; restoreMode: Binding.RestoreNone }
    z: dragging || resizing ? 50 : 5

    scale: canEdit ? (dragging ? 1.04 : 0.97) : 1
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    SequentialAnimation on rotation {
        running: root.canEdit && !root.dragging
        loops: Animation.Infinite
        NumberAnimation { to: 0.8; duration: 120 }
        NumberAnimation { to: -0.8; duration: 120 }
        onRunningChanged: if (!running) root.rotation = 0
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.bare
        radius: 30
        color: Theme.glass
        border.color: Theme.glassStroke
        border.width: 1
    }
    // Bare widgets (stickers) show an outline only while editing.
    Rectangle {
        anchors.fill: parent
        visible: root.bare && root.canEdit
        radius: 20
        color: "transparent"
        border.color: Qt.rgba(1, 1, 1, 0.35)
        border.width: 1
    }

    MouseArea {
        anchors.fill: parent
        onPressAndHold: if (!root.preview) Home.editing = true
    }

    Loader {
        id: ld
        anchors.fill: parent
        anchors.margins: root.fullBleed ? 0 : 16
        source: root.type ? "Widget" + root.type.comp + ".qml" : ""
        onLoaded: {
            if (item && item.inst !== undefined)
                item.inst = Qt.binding(() => root.inst);
        }
    }

    // ---- Edit mode: move ------------------------------------------------------------------------
    MouseArea {
        id: mover
        anchors.fill: parent
        visible: root.canEdit
        preventStealing: true
        property real offX: 0
        property real offY: 0
        property point lastFp: Qt.point(0, 0)

        onPressed: m => { offX = m.x; offY = m.y; }
        onPositionChanged: m => {
            if (!pressed || !root.pagerItem)
                return;
            const fp = mapToItem(root.pagerItem, m.x, m.y);
            if (!root.dragging) {
                if (Math.abs(m.x - offX) + Math.abs(m.y - offY) < 8)
                    return;
                root.dx = root.x;
                root.dy = root.y;
                root.dragging = true;
            }
            lastFp = fp;
            root.follow();
            pageTimer.running = fp.x < 70 || fp.x > root.pagerItem.width - 70;
        }
        onReleased: {
            pageTimer.running = false;
            if (!root.dragging)
                return;
            const cx = root.dx + root.width / 2;
            const page = Math.max(0, Math.min(root.maxPage, Math.floor(cx / root.pw)));
            const fx = Math.max(0, Math.min(1 - root.width / root.pw, (root.dx - page * root.pw) / root.pw));
            const fy = Math.max(0, Math.min(1 - root.height / root.ph, root.dy / root.ph));
            root.dragging = false;
            Home.moveWidget(root.inst.id, page, fx, fy);
        }
        onCanceled: { pageTimer.running = false; root.dragging = false; }
    }

    // Grid snap (half-unit steps, columns start at xPad like the icon grid).
    function snapped(v, origin, step) {
        return origin + Math.round((v - origin) / step) * step;
    }

    function follow() {
        if (!dragging || !flickRef)
            return;
        let nx = mover.lastFp.x + flickRef.contentX - mover.offX;
        let ny = mover.lastFp.y - mover.offY;
        if (Home.snapGrid) {
            const step = (unit + gap) / 2;
            const page = Math.max(0, Math.min(maxPage, Math.floor((nx + width / 2) / pw)));
            nx = page * pw + snapped(nx - page * pw, xPad, step);
            ny = snapped(ny, 0, step);
        }
        dx = nx;
        dy = ny;
    }

    Connections {
        target: root.flickRef
        function onContentXChanged() { root.follow(); }
    }

    // Hold the widget near a screen edge to flip pages.
    Timer {
        id: pageTimer
        interval: 700
        repeat: true
        onTriggered: {
            const p = root.pagerItem;
            if (!p)
                return;
            if (mover.lastFp.x < 70)
                root.wantPage(-1);
            else if (mover.lastFp.x > p.width - 70)
                root.wantPage(1);
        }
    }

    // ---- Edit mode: resize handle (bottom-right) ------------------------------------------------
    Rectangle {
        visible: root.canEdit
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: -6
        width: 34
        height: 34
        radius: 17
        color: Theme.accent
        z: 3

        Text {
            anchors.centerIn: parent
            text: "\u2921"
            color: Theme.accentInk
            font.pixelSize: 17
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -10
            preventStealing: true
            property point p0: Qt.point(0, 0)
            property real w0: 1
            property real h0: 1
            function snap(v, lo, hi) { return Math.max(lo, Math.min(hi, Math.round(v * 2) / 2)); }
            onPressed: m => {
                if (!root.pagerItem)
                    return;
                p0 = mapToItem(root.pagerItem, m.x, m.y);
                w0 = root.inst.w;
                h0 = root.inst.h;
                root.lw = w0;
                root.lh = h0;
                root.resizing = true;
            }
            onPositionChanged: m => {
                if (!root.resizing || !root.pagerItem)
                    return;
                const p = mapToItem(root.pagerItem, m.x, m.y);
                const step = root.unit + root.gap;
                const maxW = Math.max(1, Math.floor((root.pw - 80) / step));
                root.lw = snap(w0 + (p.x - p0.x) / step, 0.5, maxW);
                root.lh = snap(h0 + (p.y - p0.y) / step, 0.5, 3);
            }
            onReleased: {
                if (!root.resizing)
                    return;
                const w = root.lw;
                const h = root.lh;
                root.resizing = false;
                Home.resizeWidget(root.inst.id, w, h);
            }
            onCanceled: root.resizing = false
        }
    }

    // ---- Edit mode: remove (top-left) and configure (top-right) --------------------------------
    Rectangle {
        visible: root.canEdit
        x: -6
        y: -6
        width: 30
        height: 30
        radius: 15
        color: "#3a3a3c"
        border.color: Qt.rgba(1, 1, 1, 0.3)
        border.width: 1
        z: 3

        Rectangle {
            anchors.centerIn: parent
            width: 12
            height: 2
            radius: 1
            color: Theme.text
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            onClicked: Home.removeWidget(root.inst.id)
        }
    }
    Rectangle {
        visible: root.canEdit && root.type !== null && !!root.type.pick
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: -6
        width: 34
        height: 34
        radius: 17
        color: Theme.accent
        z: 3

        Text {
            anchors.centerIn: parent
            text: "\u270e"
            color: Theme.accentInk
            font.pixelSize: 16
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            onClicked: root.configure()
        }
    }
}
