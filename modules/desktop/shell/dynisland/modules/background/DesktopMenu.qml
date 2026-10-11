// =============================================================================
//  DesktopMenu — right-click menu on the empty desktop (opened from Wallpaper.qml).
//  Top card: wallpaper picker (selected one is large, with a check). Below: actions.
//  Closes on: any click outside, Esc, or choosing an action.
//
//  TO ADD AN ACTION: add a MenuRow below (icon = Material Symbols name).
// =============================================================================
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

Scope {
    id: sc
    required property var modelData     // the screen

    LazyLoader {
        active: UiState.deskMenuOpen && UiState.deskMenuScreen === sc.modelData.name

        PanelWindow {
            id: win
            screen: sc.modelData
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "dynisland-desktop-menu"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            function close() { UiState.deskMenuOpen = false }

            // one row of the action list; corner radii are per-corner so the stack reads as one rounded card
            component MenuRow: Rectangle {
                id: row
                property string icon: ""
                property string label: ""
                property real tl: 10; property real tr: 10; property real bl: 10; property real br: 10
                signal clicked()
                width: parent ? parent.width : 300; height: 52
                topLeftRadius: tl; topRightRadius: tr; bottomLeftRadius: bl; bottomRightRadius: br
                color: rma.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                Behavior on color { ColorAnimation { duration: 100 } }
                Row {
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 20 }
                    spacing: 18
                    Icon { name: row.icon; size: 24; color: Theme.surfaceFg }
                    Text { text: row.label; color: Theme.surfaceFg; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: rma; anchors.fill: parent; hoverEnabled: true; onClicked: row.clicked() }
            }

            FolderListModel {
                id: fm
                folder: "file://" + Config.appearance.wallpaperDir
                nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
                caseSensitive: false; showDirs: false
                onStatusChanged: if (status === FolderListModel.Ready) lv.syncIndex()
            }
            function curIndex() {
                for (let i = 0; i < fm.count; i++) if (fm.get(i, "filePath") === Config.appearance.wallpaper) return i;
                return 0;
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: win.close()
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: win.close() }   // click outside closes

                Column {
                    id: card
                    width: 360; spacing: 4
                    x: Math.max(8, Math.min(parent.width - width - 8, UiState.deskMenuX))
                    y: Math.max(8, Math.min(parent.height - height - 8, UiState.deskMenuY))
                    transformOrigin: Item.TopLeft
                    NumberAnimation on opacity { from: 0; to: 1; duration: 140 }
                    NumberAnimation on scale { from: 0.94; to: 1; duration: 180; easing.type: Easing.OutCubic }

                    // ---- wallpaper picker
                    Rectangle {
                        width: parent.width; height: 132
                        topLeftRadius: 30; topRightRadius: 30; bottomLeftRadius: 10; bottomRightRadius: 10
                        color: Theme.surfaceContainer
                        MouseArea { anchors.fill: parent }   // swallow clicks on the card background
                        ListView {
                            id: lv
                            anchors { fill: parent; margins: 16 }
                            orientation: ListView.Horizontal; spacing: 8; clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: fm
                            function syncIndex() { positionViewAtIndex(win.curIndex(), ListView.Beginning) }
                            Component.onCompleted: syncIndex()
                            delegate: Item {
                                id: d
                                required property string filePath
                                readonly property bool active: filePath === Config.appearance.wallpaper
                                width: active ? 150 : 62; height: lv.height
                                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                ClippingRectangle {
                                    anchors.fill: parent; radius: 18; color: Theme.surfaceContainerHigh
                                    Image { anchors.fill: parent; source: "file://" + d.filePath; asynchronous: true
                                            fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(300, 200) }
                                }
                                Rectangle {   // selected check
                                    visible: d.active; width: 40; height: 40; radius: 20; color: Theme.primary
                                    anchors.centerIn: parent
                                    Icon { anchors.centerIn: parent; name: "check"; size: 24; color: Theme.primaryFg }
                                }
                                MouseArea { anchors.fill: parent; onClicked: Config.appearance.wallpaper = d.filePath }
                            }
                        }
                        Text { visible: fm.count === 0; anchors.centerIn: parent; color: Theme.surfaceFgDim; font.pixelSize: 13
                               text: "No images in " + Config.appearance.wallpaperDir }
                    }

                    // ---- actions
                    MenuRow {
                        icon: "wallpaper"; label: "Change wallpaper"
                        onClicked: {   // next image in the folder
                            if (fm.count > 0) Config.appearance.wallpaper = fm.get((win.curIndex() + 1) % fm.count, "filePath");
                            lv.syncIndex();
                        }
                    }
                    MenuRow { icon: "settings"; label: "Open settings"; onClicked: { UiState.settingsOpen = true; win.close() } }
                    MenuRow { icon: "restart_alt"; label: "Reload shell"; bl: 30; br: 30
                              onClicked: { win.close(); Quickshell.reload(true) } }
                }
            }
        }
    }
}
