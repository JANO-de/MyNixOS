import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// The home screen: wallpaper + widgets + paged app icons, always behind the windows.
// Show it with `halo-ctl call desktop show` (empty "home" workspace). Long-press empty space
// for the wallpaper menu; long-press an icon/widget to edit (jiggle, drag to reorder).
// Drag one app onto another and hold ~550ms to merge them into a folder; drag onto a folder
// to add to it. Tap a folder to open it.
PanelWindow {
    id: root

    readonly property int dockSpace: Mode.tablet ? 120 : 104
    property string sheet: "" // "", "menu", "wallpapers", "widgets", "settings"
    property point menuAt: Qt.point(0, 0)
    property string openFolder: "" // folder id currently shown in its own sheet, or ""

    function openMenu(x, y) {
        menuAt = Qt.point(x, y);
        Wallpaper.rescan();
        sheet = "menu";
    }

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "halo-desktop"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Item {
        id: desk
        anchors.fill: parent

        WallpaperView {
            anchors.fill: parent
            spec: Wallpaper.current
        }

        // Soft scrim so icons and widgets stay readable on any wallpaper.
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.18)
        }

        // Done (edit mode)
        Rectangle {
            visible: Home.editing
            anchors.right: parent.right
            anchors.rightMargin: 28
            anchors.top: parent.top
            anchors.topMargin: 30
            z: 5
            width: doneText.implicitWidth + 36
            height: 38
            radius: 19
            color: Theme.accent

            Text {
                id: doneText
                anchors.centerIn: parent
                text: "Done"
                color: "#0b1b33"
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                onClicked: {
                    Home.editing = false;
                    Home.save();
                }
            }
        }

        // ---- Pages: widgets + icons -----------------------------------------------------------
        Item {
            id: pager
            anchors.top: parent.top
            anchors.topMargin: 76
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.dockSpace + 30
            anchors.left: parent.left
            anchors.right: parent.right

            readonly property int cellW: Home.cellW
            readonly property int cellH: Home.cellH
            readonly property int gap: 16
            readonly property int cols: Math.max(3, Math.floor((width - 80) / cellW))
            readonly property real areaW: cols * cellW
            readonly property real xPad: (width - areaW) / 2
            readonly property real unit: Math.max(110, Math.min(200, (areaW - 3 * gap) / 4))
            // Widget band (card + room for the "+" chips in edit mode); constant so editing never reflows icons.
            readonly property real widgetsH: unit + 24 + 46
            readonly property int rowsFull: Math.max(1, Math.floor(height / cellH))
            readonly property int rows0: Math.max(1, Math.floor((height - widgetsH) / cellH))
            readonly property int cap0: cols * rows0
            readonly property int capN: cols * rowsFull
            readonly property int n: Home.icons.count
            readonly property int pageCount: n <= cap0 ? 1 : 1 + Math.ceil((n - cap0) / capN)
            readonly property int curPage: Math.max(0, Math.min(pageCount - 1, Math.round(flick.contentX / Math.max(1, width))))

            property bool dragActive: false
            property var dragSlot: null
            property real fx: 0
            property real fy: 0

            // Drag-to-merge: the slot index currently dwelt on, plus its eid (looked up fresh at
            // merge/release time so a shift during the 550ms dwell can't merge the wrong icon).
            // Crossing into a new index arms mergeTimer; if the finger lingers there it merges
            // into a folder, otherwise it settles as a plain reorder (refreshDrag / mergeTimer / Slot.finish()).
            property var mergeTarget: null
            property string mergeTargetEid: ""

            function slotOf(i) {
                let p = 0;
                let k = i;
                if (i >= cap0) {
                    const j = i - cap0;
                    p = 1 + Math.floor(j / capN);
                    k = j % capN;
                }
                return { page: p, col: k % cols, row: Math.floor(k / cols) };
            }
            function slotX(i) {
                const s = slotOf(i);
                return s.page * width + xPad + s.col * cellW;
            }
            function slotY(i) {
                const s = slotOf(i);
                return (s.page === 0 ? widgetsH : 0) + s.row * cellH;
            }
            function indexAt(px, py) {
                const p = Math.max(0, Math.min(pageCount - 1, Math.floor(px / width)));
                const col = Math.max(0, Math.min(cols - 1, Math.floor((px - p * width - xPad) / cellW)));
                const rows = p === 0 ? rows0 : rowsFull;
                const row = Math.max(0, Math.min(rows - 1, Math.floor((py - (p === 0 ? widgetsH : 0)) / cellH)));
                const k = row * cols + col;
                return Math.max(0, Math.min(n - 1, p === 0 ? k : cap0 + (p - 1) * capN + k));
            }

            // Follow the finger, dwell-reorder/merge live, auto-flip pages at the screen edges.
            function refreshDrag() {
                const s = dragSlot;
                if (!s)
                    return;
                const p = container.mapFromItem(null, fx, fy);
                s.dragX = p.x - s.grabX;
                s.dragY = p.y - s.grabY;

                const target = indexAt(p.x, p.y);
                if (target !== s.index) {
                    if (target !== mergeTarget) {
                        if (mergeTarget !== null && mergeTarget !== s.index)
                            Home.moveIcon(s.index, mergeTarget);
                        mergeTarget = target;
                        mergeTargetEid = Home.icons.get(target).eid;
                        mergeTimer.restart();
                    }
                } else {
                    mergeTarget = null;
                    mergeTargetEid = "";
                    mergeTimer.stop();
                }

                const vx = pager.mapFromItem(null, fx, fy).x;
                const atEdge = vx < 70 || vx > width - 70;
                if (atEdge && !edgeTimer.running)
                    edgeTimer.start();
                else if (!atEdge)
                    edgeTimer.stop();
            }

            function goTo(p) {
                const t = Math.max(0, Math.min(pageCount - 1, p));
                snapAnim.stop();
                snapAnim.from = flick.contentX;
                snapAnim.to = t * width;
                snapAnim.start();
            }

            onPageCountChanged: if (curPage >= pageCount) goTo(pageCount - 1)

            Timer {
                id: edgeTimer
                interval: 650
                onTriggered: {
                    const vx = pager.mapFromItem(null, pager.fx, pager.fy).x;
                    if (vx < 70)
                        pager.goTo(pager.curPage - 1);
                    else if (vx > pager.width - 70)
                        pager.goTo(pager.curPage + 1);
                }
            }

            // Dwell on one target slot long enough -> merge into a folder instead of reordering.
            Timer {
                id: mergeTimer
                interval: 550
                onTriggered: {
                    const s = pager.dragSlot;
                    if (!s || !pager.mergeTargetEid)
                        return;
                    const dragIdx = Home.indexOfIcon(s.eid);
                    const targetIdx = Home.indexOfIcon(pager.mergeTargetEid);
                    if (dragIdx < 0 || targetIdx < 0 || dragIdx === targetIdx)
                        return;
                    Home.mergeIntoFolder(dragIdx, targetIdx);
                    pager.mergeTarget = null;
                    pager.mergeTargetEid = "";
                    pager.dragActive = false;
                    pager.dragSlot = null;
                    edgeTimer.stop();
                }
            }

            NumberAnimation {
                id: snapAnim
                target: flick
                property: "contentX"
                duration: 360
                easing.type: Easing.OutQuint
            }

            Flickable {
                id: flick
                anchors.fill: parent
                clip: true
                contentWidth: pager.width * pager.pageCount
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                interactive: !pager.dragActive
                boundsBehavior: Flickable.DragAndOvershootBounds

                onMovementStarted: snapAnim.stop()
                onContentXChanged: if (pager.dragActive) pager.refreshDrag()
                onDragEnded: {
                    const v = horizontalVelocity;
                    const pos = contentX / pager.width;
                    let t = Math.round(pos);
                    if (v > 450)
                        t = Math.ceil(pos - 0.05);
                    else if (v < -450)
                        t = Math.floor(pos + 0.05);
                    cancelFlick();
                    pager.goTo(t);
                }

                Item {
                    id: container
                    width: flick.contentWidth
                    height: flick.height

                    // Empty space: tap leaves edit mode, long-press opens the wallpaper menu.
                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (Home.editing) Home.editing = false
                        onPressAndHold: mouse => {
                            if (Home.editing)
                                return;
                            const p = mapToItem(desk, mouse.x, mouse.y);
                            root.openMenu(p.x, p.y);
                        }
                    }

                    // Widgets (page 1)
                    Row {
                        x: pager.xPad
                        y: 0
                        spacing: pager.gap

                        Repeater {
                            model: Home.widgets

                            WidgetHost {
                                required property string modelData
                                wid: modelData
                                width: (Home.typeOf(modelData) ? Home.typeOf(modelData).span : 1) * pager.unit
                                    + ((Home.typeOf(modelData) ? Home.typeOf(modelData).span : 1) - 1) * pager.gap
                                height: pager.unit
                            }
                        }
                    }

                    // Edit mode: add widgets
                    Flow {
                        visible: Home.editing
                        x: pager.xPad
                        y: pager.unit + 12
                        width: pager.areaW
                        spacing: 8

                        Repeater {
                            model: Home.editing ? Home.addable() : []

                            Rectangle {
                                required property var modelData
                                width: chipText.implicitWidth + 32
                                height: 34
                                radius: 17
                                color: Qt.rgba(1, 1, 1, 0.16)

                                Text {
                                    id: chipText
                                    anchors.centerIn: parent
                                    text: "+  " + parent.modelData.title
                                    color: Theme.text
                                    font.pixelSize: 13
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Home.addWidget(parent.modelData.id)
                                }
                            }
                        }
                    }

                    // Icons
                    Repeater {
                        model: Home.icons

                        delegate: Item {
                            id: slot

                            required property int index
                            required property string eid

                            property bool dragging: false
                            property real dragX: 0
                            property real dragY: 0
                            property real grabX: 0
                            property real grabY: 0
                            property real pressX: 0
                            property real pressY: 0
                            readonly property var entry: Home.entry(eid)

                            function begin() {
                                const s = mapToItem(null, pressX, pressY);
                                const here = mapToItem(container, 0, 0);
                                grabX = pressX;
                                grabY = pressY;
                                dragX = here.x;
                                dragY = here.y;
                                pager.fx = s.x;
                                pager.fy = s.y;
                                pager.dragSlot = slot;
                                pager.dragActive = true;
                                dragging = true;
                            }

                            function finish() {
                                if (!dragging)
                                    return;
                                dragging = false;
                                pager.dragActive = false;
                                // If released mid-hover (before the merge dwell fired), settle it as a plain reorder.
                                if (pager.mergeTargetEid) {
                                    const t = Home.indexOfIcon(pager.mergeTargetEid);
                                    if (t >= 0 && t !== index)
                                        Home.moveIcon(index, t);
                                }
                                pager.mergeTarget = null;
                                pager.mergeTargetEid = "";
                                mergeTimer.stop();
                                pager.dragSlot = null;
                                edgeTimer.stop();
                                Home.save();
                            }

                            visible: entry !== null && entry !== undefined
                            width: pager.cellW
                            height: pager.cellH
                            x: dragging ? dragX : pager.slotX(index)
                            y: dragging ? dragY : pager.slotY(index)
                            z: dragging ? 10 : 0
                            scale: dragging ? 1.1 : (tap.pressed && !Home.editing ? 0.92 : 1)

                            Behavior on x { enabled: !slot.dragging; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            Behavior on y { enabled: !slot.dragging; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            SequentialAnimation on rotation {
                                running: Home.editing && !slot.dragging
                                loops: Animation.Infinite
                                NumberAnimation { to: 1.6; duration: 100 }
                                NumberAnimation { to: -1.6; duration: 100 }
                                onRunningChanged: if (!running) slot.rotation = 0
                            }

                            AppIcon {
                                anchors.fill: parent
                                entry: slot.entry
                                interactive: false
                            }

                            MouseArea {
                                id: tap
                                anchors.fill: parent
                                preventStealing: slot.dragging

                                onPressed: mouse => {
                                    slot.pressX = mouse.x;
                                    slot.pressY = mouse.y;
                                    if (Home.editing)
                                        slot.begin();
                                }
                                onPositionChanged: mouse => {
                                    slot.pressX = mouse.x;
                                    slot.pressY = mouse.y;
                                    if (!slot.dragging)
                                        return;
                                    const s = mapToItem(null, mouse.x, mouse.y);
                                    pager.fx = s.x;
                                    pager.fy = s.y;
                                    pager.refreshDrag();
                                }
                                onPressAndHold: {
                                    if (!Home.editing) {
                                        Home.editing = true;
                                        slot.begin();
                                    }
                                }
                                onClicked: {
                                    if (!Home.editing && slot.entry) {
                                        if (slot.entry.isFolder)
                                            root.openFolder = slot.eid;
                                        else
                                            Home.launch(slot.entry);
                                    }
                                }
                                onReleased: slot.finish()
                                onCanceled: slot.finish()
                            }
                        }
                    }
                }
            }
        }

        // Page dots
        Row {
            visible: pager.pageCount > 1
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.dockSpace + 6
            spacing: 10

            Repeater {
                model: pager.pageCount

                Rectangle {
                    required property int index
                    width: 8
                    height: 8
                    radius: 4
                    color: Theme.text
                    opacity: index === pager.curPage ? 0.95 : 0.35
                    scale: index === pager.curPage ? 1.15 : 1
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Behavior on scale { NumberAnimation { duration: 160 } }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
                        onClicked: pager.goTo(parent.index)
                    }
                }
            }
        }

        // ---- Long-press menu and sheets ----------------------------------------------------------
        Item {
            id: overlay
            anchors.fill: parent
            z: 20
            visible: root.sheet !== "" || root.openFolder !== "" || dim.opacity > 0.01

            Rectangle {
                id: dim
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.4)
                opacity: (root.sheet !== "" || root.openFolder !== "") ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.sheet = "";
                        root.openFolder = "";
                    }
                }
            }

            // Wallpaper menu (Android-launcher style)
            Column {
                id: menu
                visible: root.sheet === "menu"
                width: Math.min(overlay.width - 48, 560)
                spacing: 8
                x: Math.max(24, Math.min(overlay.width - width - 24, root.menuAt.x - width / 2))
                y: Math.max(40, Math.min(overlay.height - height - 40, root.menuAt.y - height / 2))
                scale: root.sheet === "menu" ? 1 : 0.92
                opacity: root.sheet === "menu" ? 1 : 0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 160 } }

                Rectangle {
                    width: parent.width
                    height: thumbs.height + 32
                    radius: 36
                    color: Qt.rgba(0.11, 0.19, 0.2, 0.97)

                    Row {
                        id: thumbs
                        anchors.centerIn: parent
                        spacing: 12

                        Repeater {
                            model: Wallpaper.quick(4)

                            Item {
                                required property string modelData
                                readonly property real tw: (menu.width - 32 - 3 * 12) / 4
                                width: tw
                                height: tw * 1.35

                                WallpaperView {
                                    anchors.fill: parent
                                    spec: parent.modelData
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 10
                                    color: "transparent"
                                    border.width: parent.modelData === Wallpaper.current ? 3 : 1
                                    border.color: parent.modelData === Wallpaper.current ? "#a6f0a6" : Theme.glassStroke
                                }
                                Rectangle {
                                    visible: parent.modelData === Wallpaper.current
                                    anchors.centerIn: parent
                                    width: 44
                                    height: 44
                                    radius: 22
                                    color: "#a6f0a6"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: "#102010"
                                        font.pixelSize: 22
                                        font.weight: Font.Bold
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Wallpaper.set(parent.modelData)
                                }
                            }
                        }
                    }
                }

                Repeater {
                    model: [
                        { glyph: "▣", label: "Wallpapers", target: "wallpapers" },
                        { glyph: "⊞", label: "Widgets", target: "widgets" },
                        { glyph: "⌂", label: "Launcher settings", target: "settings" }
                    ]

                    Rectangle {
                        required property var modelData
                        width: menu.width
                        height: 64
                        radius: 28
                        color: rowTap.pressed ? Qt.rgba(0.2, 0.32, 0.33, 0.98) : Qt.rgba(0.11, 0.19, 0.2, 0.97)
                        Behavior on color { ColorAnimation { duration: 90 } }

                        Text {
                            x: 28
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.modelData.glyph
                            color: Theme.text
                            font.pixelSize: 24
                        }
                        Text {
                            x: 84
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.modelData.label
                            color: Theme.text
                            font.pixelSize: 18
                        }
                        MouseArea {
                            id: rowTap
                            anchors.fill: parent
                            onClicked: root.sheet = parent.modelData.target
                        }
                    }
                }
            }

            // Wallpapers sheet
            Sheet {
                visible: root.sheet === "wallpapers"
                anchors.centerIn: parent
                title: "Wallpapers"
                onClosed: root.sheet = "menu"

                Flow {
                    width: parent.width
                    spacing: 12

                    Repeater {
                        model: root.sheet === "wallpapers" ? Wallpaper.specs : []

                        Item {
                            required property string modelData
                            width: (parent.width - 36) / 4
                            height: width * 1.35

                            WallpaperView {
                                anchors.fill: parent
                                spec: parent.modelData
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: "transparent"
                                border.width: parent.modelData === Wallpaper.current ? 3 : 1
                                border.color: parent.modelData === Wallpaper.current ? "#a6f0a6" : Theme.glassStroke
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Wallpaper.set(parent.modelData)
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        topPadding: 8
                        text: "Add your own images to ~/Pictures/Wallpapers"
                        color: Theme.dim
                        font.pixelSize: 13
                    }
                }
            }

            // Widgets gallery
            Sheet {
                visible: root.sheet === "widgets"
                anchors.centerIn: parent
                title: "Widgets"
                onClosed: root.sheet = "menu"

                Flow {
                    width: parent.width
                    spacing: 14

                    Repeater {
                        model: Home.widgetTypes

                        Column {
                            required property var modelData
                            readonly property bool placed: Home.widgets.indexOf(modelData.id) >= 0
                            readonly property bool fits: placed || Home.usedSpan() + modelData.span <= Home.maxSpan
                            width: modelData.span * 150 + (modelData.span - 1) * 14
                            spacing: 8
                            opacity: fits ? 1 : 0.4

                            WidgetHost {
                                wid: parent.modelData.id
                                width: parent.width
                                height: 150
                            }
                            Rectangle {
                                width: parent.width
                                height: 36
                                radius: 18
                                color: parent.placed ? Qt.rgba(1, 1, 1, 0.12) : Theme.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.parent.placed ? parent.parent.modelData.title + "  ·  Remove" : "Add " + parent.parent.modelData.title
                                    color: parent.parent.placed ? Theme.text : "#0b1b33"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: parent.parent.fits
                                    onClicked: {
                                        if (parent.parent.placed)
                                            Home.removeWidget(parent.parent.modelData.id);
                                        else
                                            Home.addWidget(parent.parent.modelData.id);
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        topPadding: 6
                        text: "The widget row holds " + Home.maxSpan + " units. Long-press the home screen items to rearrange."
                        color: Theme.dim
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                    }
                }
            }

            // Launcher settings
            Sheet {
                visible: root.sheet === "settings"
                anchors.centerIn: parent
                title: "Launcher settings"
                onClosed: root.sheet = "menu"

                Column {
                    width: parent.width
                    spacing: 12

                    // Show app names
                    Rectangle {
                        width: parent.width
                        height: 60
                        radius: 24
                        color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            x: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Show app names"
                            color: Theme.text
                            font.pixelSize: 17
                        }
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            width: 56
                            height: 32
                            radius: 16
                            color: Home.showLabels ? Theme.accent : Qt.rgba(1, 1, 1, 0.2)
                            Behavior on color { ColorAnimation { duration: 140 } }

                            Rectangle {
                                y: 3
                                x: Home.showLabels ? parent.width - width - 3 : 3
                                width: 26
                                height: 26
                                radius: 13
                                color: "white"
                                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Home.showLabels = !Home.showLabels;
                                Home.save();
                            }
                        }
                    }

                    // Icon size
                    Rectangle {
                        width: parent.width
                        height: 84
                        radius: 24
                        color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            x: 24
                            y: 12
                            text: "Icon size"
                            color: Theme.text
                            font.pixelSize: 17
                        }
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 10
                            spacing: 8

                            Repeater {
                                model: ["Small", "Medium", "Large"]

                                Rectangle {
                                    required property int index
                                    required property string modelData
                                    width: 96
                                    height: 30
                                    radius: 15
                                    color: Home.density === index ? Theme.accent : Qt.rgba(1, 1, 1, 0.14)
                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.modelData
                                        color: Home.density === parent.index ? "#0b1b33" : Theme.text
                                        font.pixelSize: 13
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            Home.density = parent.index;
                                            Home.save();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Edit
                    Rectangle {
                        width: parent.width
                        height: 60
                        radius: 24
                        color: Qt.rgba(1, 1, 1, 0.08)
                        Text {
                            x: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Edit home screen"
                            color: Theme.text
                            font.pixelSize: 17
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.sheet = "";
                                Home.editing = true;
                            }
                        }
                    }

                    // Reset
                    Rectangle {
                        width: parent.width
                        height: 60
                        radius: 24
                        color: Qt.rgba(1, 0.3, 0.3, 0.14)
                        Text {
                            x: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Reset home layout"
                            color: "#ff8f8f"
                            font.pixelSize: 17
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Home.reset();
                                root.sheet = "";
                            }
                        }
                    }
                }
            }

            // Folder contents
            Sheet {
                visible: root.openFolder !== ""
                anchors.centerIn: parent
                title: (Home.folders[root.openFolder] ? Home.folders[root.openFolder].name : "")
                onClosed: root.openFolder = ""

                Column {
                    width: parent.width
                    spacing: 16

                    TextInput {
                        width: parent.width
                        horizontalAlignment: TextInput.AlignHCenter
                        text: Home.folders[root.openFolder] ? Home.folders[root.openFolder].name : ""
                        color: Theme.text
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        onEditingFinished: Home.renameFolder(root.openFolder, text)
                    }

                    Flow {
                        width: parent.width
                        spacing: 14

                        Repeater {
                            model: Home.folders[root.openFolder] ? Home.folders[root.openFolder].items : []

                            Column {
                                id: fItem
                                required property string modelData
                                width: 96
                                spacing: 6

                                AppIcon {
                                    id: fIcon
                                    width: 96
                                    height: 96
                                    interactive: false
                                    entry: DesktopEntries.byId(fItem.modelData)
                                }
                                MouseArea {
                                    anchors.fill: fIcon
                                    onClicked: {
                                        const e = DesktopEntries.byId(fItem.modelData);
                                        if (e) {
                                            root.openFolder = "";
                                            Home.launch(e);
                                        }
                                    }
                                    onPressAndHold: Home.removeFromFolder(root.openFolder, fItem.modelData)
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: "Long-press an app to take it out of the folder."
                        color: Theme.dim
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}
