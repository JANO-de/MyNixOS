import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// "Manage windows" carousel (Android ManageWindowsTaskbarShortcut / TaskbarShortcutManageWindowsView):
// thumbnails of every open window of one app, floating above the dock, aligned with the app icon and clamped
// to the screen edge. Tap a thumbnail = bring that window to the front and close; tap outside = close.
// Placement from the source: y = availableHeight - menuHeight - taskbarHeight - margin; x = min(icon.x, maxX).
// NOT verified from source: card/thumbnail sizes, corner radii, animation (they live in WM Shell ManageWindowsView).
PanelWindow {
    id: root

    property string screenName: "" // plain string: reading `screen` inside `visible` makes a binding loop
    readonly property var item: UI.winItem
    // Live list: Apps.items is rebuilt when windows open/close, UI.winItem would go stale.
    readonly property var wins: {
        if (!item)
            return [];
        for (const i of Apps.items)
            if (i.key === item.key)
                return i.windows;
        return [];
    }
    onWinsChanged: if (UI.winItem && wins.length === 0) UI.closeWindowsMenu()
    readonly property real margin: 12 // taskbar_multi_instance_menu_min_padding_from_screen_edge (value assumed)
    readonly property real thumbW: 220
    readonly property real thumbH: 150

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    visible: UI.winItem !== null && UI.winScreen === screenName
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "halo-windows"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Backdrop: tap outside closes.
    MouseArea {
        anchors.fill: parent
        onClicked: UI.closeWindowsMenu()
    }

    Rectangle {
        id: card
        readonly property real contentW: root.wins.length * root.thumbW + Math.max(0, root.wins.length - 1) * 10
        width: Math.min(root.width - 2 * root.margin, contentW + 24)
        height: root.thumbH + 24 + 28 + 40
        x: Math.max(root.margin, Math.min(root.width - width - root.margin, UI.winX - 32))
        y: Math.max(root.margin, UI.winY - height - root.margin)
        radius: 24
        color: Theme.glass
        border.color: Theme.glassStroke
        border.width: 1

        MouseArea { anchors.fill: parent } // swallow taps on the card

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 12
            orientation: ListView.Horizontal
            spacing: 10
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.wins

            delegate: Item {
                id: cell
                required property var modelData
                width: root.thumbW
                height: list.height

                Text {
                    id: title
                    anchors.top: parent.top
                    width: parent.width
                    height: 22
                    elide: Text.ElideRight
                    text: cell.modelData.title !== "" ? cell.modelData.title : cell.modelData.appId
                    color: Theme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    anchors.top: title.bottom
                    anchors.topMargin: 6
                    width: parent.width
                    height: root.thumbH
                    radius: 14
                    color: Qt.rgba(0.1, 0.1, 0.12, 1)
                    border.color: cell.modelData.activated ? Theme.accent : Theme.glassStroke
                    border.width: cell.modelData.activated ? 2 : 1
                    scale: ma.pressed ? 0.97 : 1
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    ScreencopyView {
                        id: view
                        anchors.fill: parent
                        anchors.margins: 2
                        captureSource: cell.modelData
                        live: root.visible
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        onClicked: {
                            const w = cell.modelData;
                            UI.closeWindowsMenu();
                            w.activate();
                        }
                    }

                    // Close this window (extra: Android's carousel only has tap-to-open).
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 8
                        width: 30
                        height: 30
                        radius: 15
                        color: Qt.rgba(0, 0, 0, 0.6)
                        Text {
                            anchors.centerIn: parent
                            text: "\u2715"
                            color: "white"
                            font.pixelSize: 14
                        }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            onClicked: cell.modelData.close()
                        }
                    }
                }

                // Move this window into a split half (extra, not in Android's carousel).
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 28 + root.thumbH + 8
                    spacing: 8
                    visible: !cell.modelData.activated

                    Repeater {
                        model: ["left", "right"]

                        Rectangle {
                            id: sp
                            required property string modelData
                            width: 100
                            height: 32
                            radius: 16
                            color: spTap.pressed ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.14)
                            Text {
                                anchors.centerIn: parent
                                text: sp.modelData === "left" ? "Split left" : "Split right"
                                color: Theme.text
                                font.pixelSize: 13
                            }
                            MouseArea {
                                id: spTap
                                anchors.fill: parent
                                onClicked: {
                                    const w = cell.modelData;
                                    const it = root.item;
                                    UI.closeWindowsMenu();
                                    UI.splitFromMenu({ key: it.key, pinIndex: -1, entry: it.entry, windows: [w], pick: true, name: it.name, icon: it.icon }, sp.modelData, root.screen);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
