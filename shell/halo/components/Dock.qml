import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.services

// Floating dock. Reserves space in desktop mode, overlays windows in tablet mode.
// Rises above the home screen while it is open.
PanelWindow {
    id: root

    readonly property int iconSize: Mode.tablet ? 64 : 48
    // Android taskbar spacing (res/values/dimens.xml): taskbar_icon_size 44dp, taskbar_icon_spacing 12dp per side
    // (transient taskbar = tablet: transient_taskbar_icon_spacing 10dp). Visible gap between icons = 2 x spacing.
    // Scaled to our icon size (icon px / 44dp).
    readonly property real gap: Math.round(iconSize * 2 * (Mode.tablet ? 10 : 12) / 44)

    // Android TaskbarView order: [All Apps][divider if no recents][pinned][divider if recents][recents/running]
    readonly property var pinnedItems: Apps.items.filter(i => i.pinIndex >= 0)
    readonly property var recentItems: Apps.items.filter(i => i.pinIndex < 0)
    readonly property real dividerW: 4
    readonly property bool dividerAfterAllApps: recentItems.length === 0 && pinnedItems.length > 0
    readonly property bool dividerForRecents: recentItems.length > 0 && pinnedItems.length > 0

    anchors.bottom: true
    margins.bottom: 10
    implicitWidth: pill.width
    implicitHeight: iconSize + 24
    color: "transparent"
    exclusionMode: Mode.tablet ? ExclusionMode.Ignore : ExclusionMode.Auto

    WlrLayershell.namespace: "halo-dock"
    WlrLayershell.layer: (UI.homeOpen || UI.overviewOpen || UI.overviewDragging) ? WlrLayer.Overlay : WlrLayer.Top
    visible: UI.dockShown || pill.opacity > 0.01

    // Publish where the pill sits (screen coordinates) so the home screen can hit-test drops onto it.
    Binding { target: UI; property: "dockRect"; value: root.screen ? Qt.rect((root.screen.width - pill.width) / 2, root.screen.height - 10 - pill.height, pill.width, pill.height) : Qt.rect(0, 0, 0, 0) }
    Binding { target: UI; property: "dockScreenW"; value: root.screen ? root.screen.width : 0 }
    Binding { target: UI; property: "dockScreenH"; value: root.screen ? root.screen.height : 0 }
    Binding { target: UI; property: "dockRowLeft"; value: (root.screen ? (root.screen.width - pill.width) / 2 : 0) + 14 }
    Binding { target: UI; property: "dockLead"; value: root.iconSize + row.spacing + (root.dividerAfterAllApps ? root.dividerW + row.spacing : 0) }
    Binding { target: UI; property: "dockStep"; value: root.iconSize + row.spacing }

    Rectangle {
        id: pill
        anchors.bottom: parent.bottom
        // Follows the finger during the bottom swipe inside an app (iPad dock reveal).
        anchors.bottomMargin: UI.dockDragging ? -(height + 40) * (1 - UI.dockPeek) : (UI.dockShown ? 0 : -(height + 40))
        opacity: UI.dockDragging ? Math.min(1, UI.dockPeek * 2) : (UI.dockShown ? 1 : 0)
        Behavior on anchors.bottomMargin { enabled: !UI.dockDragging; NumberAnimation { duration: 417; easing.type: Easing.OutQuint } } // TRANSIENT_TASKBAR_STASH_DURATION
        Behavior on opacity { enabled: !UI.dockDragging; NumberAnimation { duration: UI.dockShown ? 50 : 417 } } // TRANSIENT_TASKBAR_STASH_ALPHA_DURATION
        anchors.horizontalCenter: parent.horizontalCenter
        width: row.implicitWidth + 28
        height: root.iconSize + 24
        radius: Theme.radius
        color: Theme.glass
        border.color: UI.dockDropHot ? Theme.accent : Theme.glassStroke
        border.width: UI.dockDropHot ? 3 : 1
        scale: UI.dockDropHot ? 1.06 : 1
        Behavior on scale { NumberAnimation { duration: 120 } }

        // Insertion marker while an icon from the home screen hovers the dock.
        Rectangle {
            visible: UI.dockDropHot
            x: 14 + UI.dockLead + UI.dockDropIndex * UI.dockStep - root.gap / 2 - 2
            y: 12
            width: 4
            height: root.iconSize
            radius: 2
            color: Theme.accent
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: root.gap

            // All Apps button: first in the taskbar (Android), in tablet mode too.
            Item {
                width: root.iconSize
                height: root.iconSize
                scale: launcherArea.pressed ? 0.88 : 1
                Behavior on scale { NumberAnimation { duration: 90 } }

                Grid {
                    anchors.centerIn: parent
                    columns: 3
                    spacing: 4

                    Repeater {
                        model: 9
                        Rectangle {
                            width: 10
                            height: 10
                            radius: 3
                            color: Theme.text
                            opacity: 0.85
                        }
                    }
                }

                MouseArea {
                    id: launcherArea
                    anchors.fill: parent
                    onClicked: UI.toggleHome()
                }
            }

            // One icon cell (pinned and recent/running apps share it).
            Component {
                id: cellComp

                Item {
                    id: cell
                    required property var modelData

                    readonly property bool pinnedItem: modelData.pinIndex >= 0
                    property real dragDx: 0
                    property bool dragging: false
                    property bool menuOpened: false // long-press menu opened by this press (Android: keep dragging = drag the icon)
                    property bool launchDragged: false // dragged up out of the dock (Slide Over / Split View)

                    width: root.iconSize
                    height: root.iconSize
                    z: dragging ? 10 : 0
                    scale: dragging ? 1.12 : (area.pressed && !UI.dockEditing ? 0.88 : 1)
                    Behavior on scale { NumberAnimation { duration: 90 } }
                    transform: Translate { x: cell.dragDx }

                    SequentialAnimation on rotation {
                        running: UI.dockEditing && !cell.dragging
                        loops: Animation.Infinite
                        NumberAnimation { to: 2; duration: 100 }
                        NumberAnimation { to: -2; duration: 100 }
                        onRunningChanged: if (!running) cell.rotation = 0
                    }

                    Rectangle {
                        visible: Theme.themedIcons
                        anchors.fill: parent
                        radius: width / 4
                        color: Theme.iconTile
                    }

                    Image {
                        anchors.centerIn: parent
                        width: parent.width * (Theme.themedIcons ? 0.7 : 1)
                        height: width
                        source: Apps.iconSource(cell.modelData.icon)
                        sourceSize: Qt.size(root.iconSize * 2, root.iconSize * 2)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Rectangle {
                        visible: Apps.isAndroid(cell.modelData.entry)
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: -2
                        width: Math.max(16, parent.width * 0.28)
                        height: width
                        radius: width / 2
                        color: Theme.accent
                        border.width: 2
                        border.color: Theme.iconTile

                        Text {
                            anchors.centerIn: parent
                            text: "A"
                            color: Theme.accentInk
                            font.pixelSize: parent.width * 0.6
                            font.weight: Font.Bold
                        }
                    }

                    Rectangle {
                        visible: cell.modelData.windows.length > 0
                        anchors.top: parent.bottom
                        anchors.topMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 5
                        height: 5
                        radius: 3
                        color: Apps.isActive(cell.modelData) ? Theme.accent : Theme.dim
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        preventStealing: !UI.dockEditing // keep the touch for the swipe-up
                        property real startX: 0
                        property real startY: 0

                        onPressed: m => {
                            const p = mapToItem(null, m.x, m.y);
                            startX = p.x;
                            startY = p.y;
                            cell.launchDragged = false;
                            cell.menuOpened = false;
                        }
                        onPositionChanged: m => {
                            if (!UI.dockEditing && pressed) {
                                // Swipe up out of the dock: drag the app to an edge (Slide Over) or further in (Split View).
                                const q = mapToItem(null, m.x, m.y);
                                const up = startY - q.y;
                                // TaskbarDragController: after the long-press popup opened, moving the finger starts the drag.
                                const afterHold = cell.menuOpened && Math.hypot(q.x - startX, q.y - startY) > 12;
                                if (!UI.dockDragActive && ((up > 22 && Math.abs(q.x - startX) < up * 3) || afterHold)) {
                                    if (afterHold)
                                        UI.closeAppMenu();
                                    cell.launchDragged = true;
                                    UI.beginDockDrag(cell.modelData, root.screen ? root.screen.name : "");
                                }
                                if (UI.dockDragActive && cell.launchDragged)
                                    UI.moveDockDrag(UI.dockRect.x + q.x, UI.dockRect.y + q.y);
                                return;
                            }
                            if (!UI.dockEditing || !pressed || !cell.pinnedItem)
                                return;
                            const dx = mapToItem(null, m.x, 0).x - startX;
                            if (Math.abs(dx) > 8)
                                cell.dragging = true;
                            if (cell.dragging)
                                cell.dragDx = dx;
                        }
                        onReleased: {
                            if (cell.launchDragged) {
                                UI.finishDockDrag(root.screen);
                                return;
                            }
                            if (cell.dragging) {
                                // Reorder: how many slots did it travel? (visible pinned items only)
                                const list = Apps.items.filter(i => i.pinIndex >= 0);
                                const vi = list.findIndex(i => i.key === cell.modelData.key);
                                const steps = Math.round(cell.dragDx / (root.iconSize + row.spacing));
                                const ti = Math.max(0, Math.min(list.length - 1, vi + steps));
                                cell.dragging = false;
                                cell.dragDx = 0;
                                if (vi >= 0 && ti !== vi)
                                    Apps.movePin(cell.modelData.pinIndex, list[ti].pinIndex);
                            }
                        }
                        onCanceled: {
                            cell.dragging = false;
                            cell.dragDx = 0;
                            if (cell.launchDragged)
                                UI.cancelDockDrag();
                        }
                        onClicked: {
                            if (cell.launchDragged) {
                                cell.launchDragged = false;
                                return;
                            }
                            if (UI.dockEditing)
                                return;
                            UI.closeHome();
                            Apps.activate(cell.modelData);
                        }
                        onPressAndHold: {
                            // Android: long-press opens the app menu (split left/right, ...); "Edit dock" is in it.
                            if (!UI.dockEditing && !cell.dragging && !cell.launchDragged) {
                                const p = cell.mapToItem(null, cell.width / 2, 0);
                                UI.openAppMenu(cell.modelData, UI.dockRect.x + p.x, UI.dockRect.y + p.y - 8, root.screen ? root.screen.name : "");
                                cell.menuOpened = true;
                            }
                        }
                    }

                    // Jiggle-mode badge: "-" unpins, "+" pins a running app.
                    Rectangle {
                        visible: UI.dockEditing && (cell.pinnedItem || cell.modelData.entry)
                        x: -6
                        y: -6
                        width: 26
                        height: 26
                        radius: 13
                        color: "#3a3a3c"
                        border.color: Qt.rgba(1, 1, 1, 0.3)
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: cell.pinnedItem ? "\u2212" : "+"
                            color: Theme.text
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            onClicked: {
                                if (cell.pinnedItem)
                                    Apps.unpin(cell.modelData.pinIndex);
                                else
                                    Apps.pin(cell.modelData.entry);
                            }
                        }
                    }
                }
            }

            Item {
                visible: root.dividerAfterAllApps
                width: root.dividerW
                height: root.iconSize
                Rectangle {
                    anchors.centerIn: parent
                    width: 2
                    height: root.iconSize * 0.6
                    radius: 1
                    color: Theme.dim
                    opacity: 0.6
                }
            }

            Repeater {
                model: root.pinnedItems
                delegate: cellComp
            }

            Item {
                visible: root.dividerForRecents
                width: root.dividerW
                height: root.iconSize
                Rectangle {
                    anchors.centerIn: parent
                    width: 2
                    height: root.iconSize * 0.6
                    radius: 1
                    color: Theme.dim
                    opacity: 0.6
                }
            }

            Repeater {
                model: root.recentItems
                delegate: cellComp
            }

            // Leaves dock edit mode.
            Item {
                visible: UI.dockEditing
                width: doneText.implicitWidth + 32
                height: root.iconSize

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 38
                    radius: 19
                    color: Theme.accent
                    Text {
                        id: doneText
                        anchors.centerIn: parent
                        text: "Done"
                        color: Theme.accentInk
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: UI.dockEditing = false
                }
            }
        }
    }
}
