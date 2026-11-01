import QtQuick
import qs.common

// Full-window viewer: swipe, pinch / double-tap / wheel zoom, drag down to close, drag up (or "i") for the info sheet,
// filmstrip scrubber, action bar, slideshow, inline video (QtMultimedia, falls back to xdg-open).
Item {
    id: v
    property var host
    property bool chrome: true
    property bool zoomed: false
    property bool infoOpen: false
    property real dragY: 0
    property var info: ({})
    readonly property var ent: (host && host.cur < host.shown.length) ? host.shown[host.cur] : null
    readonly property bool isFav: ent !== null && host.favs[ent.path] === true
    readonly property var btns: {
        if (host.page === "trash")
            return [{ id: "restore", ico: "restore" }, { id: "delperm", ico: "trash" }];
        const b = [{ id: "copy", ico: "share" }, { id: "fav", ico: "heart" }];
        if (!(ent && ent.video))
            b.push({ id: "rotl", ico: "rotl" }, { id: "rotr", ico: "rotr" });
        b.push({ id: "slide", ico: host.slideOn ? "pause" : "play" }, { id: "info", ico: "info" }, { id: "trash", ico: "trash" }, { id: "more", ico: "more" });
        return b;
    }

    function frac(s) {
        const p = ("" + s).split("/");
        return p.length === 2 && +p[1] ? +p[0] / +p[1] : +s;
    }
    readonly property var infoRows: {
        const r = [];
        const e = ent;
        if (!e)
            return r;
        const i = info;
        r.push(["Modified", Qt.formatDateTime(new Date(e.mtime * 1000), "d MMM yyyy, HH:mm")]);
        if (i.dt)
            r.push(["Taken", i.dt.replace(/^(\d+):(\d+):(\d+)/, "$1-$2-$3")]);
        r.push(["Size", host.human(e.size)]);
        if (i.dim)
            r.push(["Dimensions", i.dim.replace("x", " \u00d7 ")]);
        if (i.dur)
            r.push(["Duration", Math.floor(i.dur / 60) + ":" + ("0" + (i.dur % 60)).slice(-2)]);
        const cam = ((i.make || "") + " " + (i.model || "")).trim();
        if (cam !== "")
            r.push(["Camera", cam]);
        const ex = [];
        if (i.f)
            ex.push("f/" + frac(i.f).toFixed(1));
        if (i.exp)
            ex.push(i.exp + " s");
        if (i.iso)
            ex.push("ISO " + i.iso);
        if (i.fl)
            ex.push(frac(i.fl).toFixed(0) + " mm");
        if (ex.length)
            r.push(["Exposure", ex.join("  \u00b7  ")]);
        if (e.album !== "")
            r.push(["Album", e.album]);
        r.push(["Path", e.path]);
        return r;
    }

    function loadInfo() {
        if (!ent)
            return;
        host.exec(["bash", host.sd + "info.sh", ent.path], t => {
            const m = {};
            for (const l of t.split("\n")) {
                const k = l.indexOf("=");
                if (k > 0 && l.substring(k + 1) !== "")
                    m[l.substring(0, k)] = l.substring(k + 1);
            }
            v.info = m;
        });
    }
    function showInfo() {
        infoOpen = true;
        loadInfo();
    }
    function openAt(i) {
        zoomed = false;
        infoOpen = false;
        chrome = !host.slideOn;
        dragY = 0;
        info = ({});
        Qt.callLater(() => {
            pager.positionViewAtIndex(i, ListView.Beginning);
            pager.currentIndex = i;
            film.positionViewAtIndex(i, ListView.Center);
        });
    }
    function go(i) {
        if (i < 0 || i >= pager.count)
            return;
        host.cur = i;
        pager.currentIndex = i;
    }
    function act(id, item) {
        if (!ent)
            return;
        const p = ent.path;
        switch (id) {
        case "copy": if (ent.video) host.copyPaths([p]); else host.copyImage(p); break;
        case "fav": host.toggleFav([p]); break;
        case "rotl": host.rotate([p], -90); break;
        case "rotr": host.rotate([p], 90); break;
        case "slide": host.slideOn = !host.slideOn; if (host.slideOn) chrome = false; break;
        case "info": if (infoOpen) infoOpen = false; else showInfo(); break;
        case "trash": host.trashPaths([p]); break;
        case "restore": host.restorePaths([p]); break;
        case "delperm": host.deleteForever([p]); break;
        case "more": host.itemMenu(item, 0, -10, [p]); break;
        }
    }

    Connections {
        target: v.host
        function onCurChanged() {
            v.zoomed = false;
            film.positionViewAtIndex(v.host.cur, ListView.Center);
            if (v.infoOpen)
                v.loadInfo();
        }
        function onViewingChanged() {
            if (!v.host.viewing)
                v.host.slideOn = false;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: Math.max(0.15, 1 - Math.abs(v.dragY) / 420)
    }

    // ---- pager --------------------------------------------------------------------------------
    Item {
        id: stage
        anchors.fill: parent
        transform: Translate { y: v.dragY }
        scale: 1 - Math.min(0.25, Math.abs(v.dragY) / 1200)

        ListView {
            id: pager
            anchors.fill: parent
            orientation: ListView.Horizontal
            snapMode: ListView.SnapOneItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: 220
            interactive: !v.zoomed && !v.infoOpen
            cacheBuffer: width
            boundsBehavior: Flickable.StopAtBounds
            model: v.visible ? v.host.shown : []
            onMovementEnded: v.host.cur = currentIndex
            onCountChanged: {
                if (!v.host.viewing)
                    return;
                if (count === 0) {
                    v.host.viewing = false;
                    return;
                }
                const i = Math.min(v.host.cur, count - 1);
                v.host.cur = i;
                positionViewAtIndex(i, ListView.Beginning);
                currentIndex = i;
            }

            delegate: Item {
                id: page
                required property var modelData
                readonly property bool isCur: ListView.isCurrentItem
                width: pager.width
                height: pager.height
                clip: true
                onIsCurChanged: {
                    if (!isCur) {
                        holder.scale = 1;
                        vl.active = false;
                    }
                }

                Item {
                    id: holder
                    width: page.width
                    height: page.height
                    onScaleChanged: {
                        if (page.isCur)
                            v.zoomed = scale > 1.02;
                        if (scale <= 1.02) {
                            x = 0;
                            y = 0;
                        }
                    }
                    Image {
                        anchors.fill: parent
                        source: v.host.srcOf(page.modelData)
                        sourceSize: Qt.size(2400, 2400)
                        asynchronous: true
                        autoTransform: true
                        fillMode: Image.PreserveAspectFit
                    }
                }
                PinchHandler {
                    target: holder
                    minimumScale: 1
                    maximumScale: 6
                    minimumRotation: 0
                    maximumRotation: 0
                }
                DragHandler {
                    target: holder
                    enabled: holder.scale > 1.02
                }
                WheelHandler {
                    onWheel: event => {
                        const s = holder.scale * (1 + event.angleDelta.y / 1200);
                        holder.scale = Math.max(1, Math.min(6, s));
                    }
                }
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onSingleTapped: v.chrome = !v.chrome
                    onDoubleTapped: holder.scale = holder.scale > 1.02 ? 1 : 2.5
                }

                // video
                Loader {
                    id: vl
                    anchors.fill: parent
                    active: false
                    source: "video/VideoPane.qml"
                    onLoaded: item.src = "file://" + page.modelData.path
                    onStatusChanged: {
                        if (status === Loader.Error) {
                            active = false;
                            v.host.openExternal(page.modelData.path);
                            v.host.toast("Opened in external player");
                        }
                    }
                }
                Rectangle {
                    visible: page.modelData.video && !vl.active
                    anchors.centerIn: parent
                    width: 84
                    height: 84
                    radius: 42
                    color: Qt.rgba(0, 0, 0, 0.55)
                    border.width: 2
                    border.color: "#ffffff"
                    Ico { anchors.centerIn: parent; anchors.horizontalCenterOffset: 3; name: "play"; filled: true; size: 34; color: "#ffffff" }
                    MouseArea { anchors.fill: parent; onClicked: vl.active = true }
                }
            }
        }

        DragHandler {
            target: null
            enabled: !v.zoomed
            xAxis.enabled: false
            onActiveTranslationChanged: if (active) v.dragY = activeTranslation.y
            onActiveChanged: {
                if (!active) {
                    if (v.dragY > 140)
                        v.host.viewing = false;
                    else if (v.dragY < -110)
                        v.showInfo();
                    v.dragY = 0;
                }
            }
        }
    }

    // ---- side arrows --------------------------------------------------------------------------
    Rectangle {
        visible: v.chrome && v.host.cur > 0 && !v.zoomed
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 48
        height: 48
        radius: 24
        color: Qt.rgba(0, 0, 0, 0.45)
        Ico { anchors.centerIn: parent; name: "back"; size: 24; color: "#ffffff" }
        MouseArea { anchors.fill: parent; onClicked: v.go(v.host.cur - 1) }
    }
    Rectangle {
        visible: v.chrome && v.host.cur < v.host.shown.length - 1 && !v.zoomed
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 48
        height: 48
        radius: 24
        color: Qt.rgba(0, 0, 0, 0.45)
        Ico { anchors.centerIn: parent; name: "fwd"; size: 24; color: "#ffffff" }
        MouseArea { anchors.fill: parent; onClicked: v.go(v.host.cur + 1) }
    }

    // ---- bottom chrome: filmstrip + actions ---------------------------------------------------
    Rectangle {
        id: bottom
        visible: v.chrome && !v.infoOpen
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 170
        gradient: Gradient {
            GradientStop { position: 0; color: "#00000000" }
            GradientStop { position: 1; color: "#cc000000" }
        }
        ListView {
            id: film
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: bar.top
            anchors.bottomMargin: 8
            height: 60
            orientation: ListView.Horizontal
            spacing: 4
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            leftMargin: width / 2 - 28
            rightMargin: width / 2 - 28
            model: v.visible ? v.host.shown : []
            delegate: Item {
                id: fi
                required property var modelData
                required property int index
                readonly property bool here: index === v.host.cur
                width: here ? 56 : 44
                height: 60
                Behavior on width { NumberAnimation { duration: 140 } }
                RoundImg {
                    anchors.centerIn: parent
                    width: parent.width
                    height: fi.here ? 56 : 44
                    radius: 8
                    px: 112
                    source: v.host.srcOf(fi.modelData)
                }
                MouseArea { anchors.fill: parent; onClicked: v.go(fi.index) }
            }
        }
        Row {
            id: bar
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            spacing: 6
            Repeater {
                model: v.btns
                Rectangle {
                    id: b
                    required property var modelData
                    width: 52
                    height: 52
                    radius: 26
                    color: bm.pressed ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.1)
                    scale: bm.pressed ? 0.92 : 1
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    Ico {
                        anchors.centerIn: parent
                        name: b.modelData.ico
                        size: 24
                        filled: b.modelData.id === "fav" && v.isFav
                        color: b.modelData.id === "fav" && v.isFav ? "#ff6b81" : (b.modelData.id === "trash" || b.modelData.id === "delperm" ? "#ff8a80" : "#ffffff")
                    }
                    MouseArea { id: bm; anchors.fill: parent; onClicked: v.act(b.modelData.id, b) }
                }
            }
        }
    }

    // ---- info sheet ---------------------------------------------------------------------------
    MouseArea {
        visible: v.infoOpen
        anchors.fill: parent
        onClicked: v.infoOpen = false
    }
    Rectangle {
        id: sheet
        width: Math.min(560, parent.width)
        anchors.horizontalCenter: parent.horizontalCenter
        height: Math.min(parent.height * 0.6, 120 + v.infoRows.length * 40)
        y: v.infoOpen ? parent.height - height : parent.height
        radius: 28
        color: AppTheme.cardHigh
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 10; width: 40; height: 4; radius: 2; color: AppTheme.line }
        DragHandler {
            target: null
            xAxis.enabled: false
            onActiveChanged: if (!active && activeTranslation.y > 60) v.infoOpen = false
        }
        Text { x: 28; y: 26; width: parent.width - 56; text: v.ent ? v.ent.name : ""; elide: Text.ElideMiddle; color: AppTheme.text; font.pixelSize: 19; font.weight: Font.DemiBold }
        Flickable {
            x: 28
            y: 66
            width: parent.width - 56
            height: parent.height - 80
            contentHeight: infoCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: infoCol
                width: parent.width
                spacing: 4
                Repeater {
                    model: v.infoRows
                    Item {
                        id: ir
                        required property var modelData
                        width: infoCol.width
                        height: Math.max(34, valTxt.implicitHeight + 10)
                        Text { width: 100; anchors.top: parent.top; anchors.topMargin: 6; text: ir.modelData[0]; color: AppTheme.dim; font.pixelSize: 14 }
                        Text { id: valTxt; x: 110; width: parent.width - 110; anchors.top: parent.top; anchors.topMargin: 6; text: ir.modelData[1]; color: AppTheme.text; font.pixelSize: 14; wrapMode: Text.WrapAnywhere }
                    }
                }
            }
        }
    }

    // ---- slideshow + keys ---------------------------------------------------------------------
    Timer {
        interval: 3500
        repeat: true
        running: v.host.slideOn && v.host.viewing && !(v.ent && v.ent.video)
        onTriggered: v.go(v.host.cur + 1 >= pager.count ? 0 : v.host.cur + 1)
    }
    Shortcut { sequence: "Left"; enabled: v.host.viewing && v.host.dlg === null; onActivated: v.go(v.host.cur - 1) }
    Shortcut { sequence: "Right"; enabled: v.host.viewing && v.host.dlg === null; onActivated: v.go(v.host.cur + 1) }
    Shortcut { sequence: "Escape"; enabled: v.host.viewing && v.host.dlg === null; onActivated: { if (v.infoOpen) v.infoOpen = false; else v.host.viewing = false; } }
    Shortcut { sequence: "Space"; enabled: v.host.viewing && v.host.dlg === null; onActivated: v.act("slide", null) }
    Shortcut { sequence: "I"; enabled: v.host.viewing && v.host.dlg === null; onActivated: v.act("info", null) }
    Shortcut { sequence: "F"; enabled: v.host.viewing && v.host.dlg === null && v.host.page !== "trash"; onActivated: v.act("fav", null) }
    Shortcut { sequence: "Delete"; enabled: v.host.viewing && v.host.dlg === null && v.host.page !== "trash"; onActivated: v.act("trash", null) }
}
