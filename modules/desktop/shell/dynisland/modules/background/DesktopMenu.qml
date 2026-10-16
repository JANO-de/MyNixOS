// =============================================================================
//  DesktopMenu — right-click menu on the empty desktop (opened from Wallpaper.qml).
//  Top card: wallpaper picker (selected one is large, with a check). Below: actions.
//  Rows with a chevron (Wallpaper & style, Widgets) open a submenu on hover; changes
//  there apply live through Config (same keys as Settings).
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

            // submenu: "" | style | widgets (opens on hover, closes 250 ms after the mouse leaves)
            property string sub: ""
            property real subY: 0
            Timer { id: subClose; interval: 250; onTriggered: win.sub = "" }
            function hoverSub(h, name, row) {
                if (h) { subClose.stop(); sub = name; subY = card.y + row.y }
                else subClose.restart()
            }

            // one row of the action list; corner radii are per-corner so the stack reads as one rounded card
            component MenuRow: Rectangle {
                id: row
                property string icon: ""
                property string label: ""
                property real tl: 10; property real tr: 10; property real bl: 10; property real br: 10
                property bool chevron: false
                readonly property bool hovered: rma.containsMouse
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
                Icon { visible: row.chevron; name: "chevron_right"; size: 20; color: Theme.surfaceFgDim
                       anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter } }
                MouseArea { id: rma; anchors.fill: parent; hoverEnabled: true; onClicked: row.clicked() }
            }

            // submenu card: children are stacked vertically inside
            component SubCard: Rectangle {
                default property alias content: subCol.data
                width: 340; height: subCol.implicitHeight + 24
                radius: 26; color: Theme.surfaceContainer
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }   // swallow clicks
                Column { id: subCol; x: 12; y: 12; width: parent.width - 24; spacing: 2 }
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
                        id: styleRow
                        icon: "palette"; label: "Wallpaper & style"; chevron: true
                        onHoveredChanged: win.hoverSub(hovered, "style", styleRow)
                    }
                    MenuRow {
                        id: widgetsRow
                        icon: "widgets"; label: "Widgets"; chevron: true
                        onHoveredChanged: win.hoverSub(hovered, "widgets", widgetsRow)
                    }
                    MenuRow {
                        icon: "wallpaper"; label: "Change wallpaper"
                        onHoveredChanged: if (hovered) win.sub = ""
                        onClicked: {   // next image in the folder
                            if (fm.count > 0) Config.appearance.wallpaper = fm.get((win.curIndex() + 1) % fm.count, "filePath");
                            lv.syncIndex();
                        }
                    }
                    MenuRow { icon: "settings"; label: "Open settings"; onHoveredChanged: if (hovered) win.sub = ""; onClicked: { UiState.settingsOpen = true; win.close() } }
                    MenuRow { icon: "restart_alt"; label: "Reload shell"; bl: 30; br: 30
                              onHoveredChanged: if (hovered) win.sub = ""
                              onClicked: { win.close(); Quickshell.reload(true) } }
                }

                // ---- submenus (right of the card, or left when there is no room)
                Component {
                    id: styleComp
                    SubCard {
                        SettingRow { implicitHeight: 40; label: "Dark mode"
                            Toggle { checked: Config.appearance.darkMode; onToggled: Config.appearance.darkMode = !Config.appearance.darkMode } }
                        SettingRow { implicitHeight: 30; label: "Color scheme" }
                        Chips {
                            width: parent.width; current: Config.appearance.scheme
                            model: [ { label: "Tonal spot", value: "scheme-tonal-spot" }, { label: "Vibrant", value: "scheme-vibrant" },
                                     { label: "Expressive", value: "scheme-expressive" }, { label: "Fruit salad", value: "scheme-fruit-salad" },
                                     { label: "Rainbow", value: "scheme-rainbow" }, { label: "Content", value: "scheme-content" },
                                     { label: "Monochrome", value: "scheme-monochrome" } ]
                            onPicked: v => Config.appearance.scheme = v
                        }
                        SettingRow { implicitHeight: 40; label: "Accent color" }
                        Swatches {
                            width: parent.width; current: Config.appearance.accentOverride
                            colors: ["", "#a8c7fa", "#f2b8b5", "#8bd5a0", "#f9d56e", "#d0a8ff", "#ffb68a", "#7ee0e0", "#ff8fb1"]
                            onPicked: c => Config.appearance.accentOverride = c
                        }
                        SettingRow { implicitHeight: 40; label: "Wallpaper fit" }
                        Chips {
                            width: parent.width; current: Config.appearance.wallpaperFill
                            model: [ { label: "Fill (crop)", value: "crop" }, { label: "Fit", value: "fit" }, { label: "Stretch", value: "stretch" } ]
                            onPicked: v => Config.appearance.wallpaperFill = v
                        }
                        SettingRow { implicitHeight: 48; label: "Dim"
                            SSlider { implicitWidth: 180; from: 0; to: 0.8; stepSize: 0.05; value: Config.appearance.wallpaperDim; onMoved: v => Config.appearance.wallpaperDim = v } }
                    }
                }
                Component {
                    id: widgetsComp
                    SubCard {
                        SettingRow { implicitHeight: 40; label: "Clock"
                            Toggle { checked: Config.widgets.clock; onToggled: Config.widgets.clock = !Config.widgets.clock } }
                        SettingRow { implicitHeight: 40; label: "Weather"
                            Toggle { checked: Config.widgets.weather; onToggled: Config.widgets.weather = !Config.widgets.weather } }
                        SettingRow { implicitHeight: 40; label: "Media"
                            Toggle { checked: Config.widgets.media; onToggled: Config.widgets.media = !Config.widgets.media } }
                        SettingRow { implicitHeight: 40; label: "System monitor"
                            Toggle { checked: Config.widgets.system; onToggled: Config.widgets.system = !Config.widgets.system } }
                        SettingRow { implicitHeight: 40; label: "Calendar"
                            Toggle { checked: Config.widgets.calendar; onToggled: Config.widgets.calendar = !Config.widgets.calendar } }
                        SettingRow { implicitHeight: 48; label: "Corner radius"
                            SSlider { implicitWidth: 180; from: 0; to: 44; stepSize: 1; suffix: " px"; value: Config.widgets.cardRadius; onMoved: v => Config.widgets.cardRadius = v } }
                        SettingRow { implicitHeight: 44; label: "Reset positions"
                            Chips { model: [ { label: "Reset", value: "r" } ]; onPicked: v => Config.widgets.positions = ({}) } }
                    }
                }
                Loader {
                    id: subLoader
                    active: win.sub !== ""
                    sourceComponent: win.sub === "style" ? styleComp : widgetsComp
                    x: (card.x + card.width + 8 + 340 > parent.width) ? card.x - 340 - 8 : card.x + card.width + 8
                    y: Math.max(8, Math.min(win.subY, parent.height - (item ? item.height : 0) - 8))
                    HoverHandler { onHoveredChanged: { if (hovered) subClose.stop(); else subClose.restart() } }
                }
            }
        }
    }
}
