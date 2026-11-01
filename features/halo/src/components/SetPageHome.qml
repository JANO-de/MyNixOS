import QtQuick
import qs.services

// Settings > Home screen: labels, icon size, edit mode, reset, wallpaper.
Column {
    id: page

    property bool confirmReset: false

    width: parent ? parent.width : 600
    spacing: 22

    Component.onCompleted: Wallpaper.rescan()

    SetGroup {
        SetRow {
            glyph: "Aa"
            title: "Show app names"
            onClicked: {
                Home.showLabels = !Home.showLabels;
                Home.save();
            }

            SetSwitch {
                checked: Home.showLabels
                onToggled: {
                    Home.showLabels = !Home.showLabels;
                    Home.save();
                }
            }
        }
        SetRow {
            glyph: "✎"
            title: "Edit home screen"
            subtitle: "Rearrange, remove, add widgets"
            chevron: true
            onClicked: {
                Home.editing = true;
                UI.closeSettings();
                UI.goHome();
            }
        }
    }

    SetGroup {
        title: "Icon size"
        SetRadio {
            options: ["Small", "Default", "Large"]
            current: Home.density
            onPicked: i => {
                Home.density = i;
                Home.save();
            }
        }
    }

    SetGroup {
        title: "Wallpaper"

        Flow {
            id: wp
            width: parent.width
            spacing: 12

            readonly property real tw: (width - 2 * 12) / 3

            Repeater {
                model: Wallpaper.specs

                Item {
                    required property string modelData

                    width: wp.tw
                    height: wp.tw * 1.2

                    WallpaperView {
                        anchors.fill: parent
                        spec: parent.modelData
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: "transparent"
                        border.width: parent.modelData === Wallpaper.current ? 3 : 1
                        border.color: parent.modelData === Wallpaper.current ? Theme.accent : Theme.glassStroke
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Wallpaper.set(parent.modelData)
                    }
                }
            }
        }
    }

    SetGroup {
        SetRow {
            glyph: "↺"
            title: "Reset home screen layout"
            subtitle: page.confirmReset ? "Tap again to confirm. Icons go back to alphabetical order." : "Icons, folders and widgets"
            onClicked: {
                if (page.confirmReset) {
                    Home.reset();
                    page.confirmReset = false;
                } else {
                    page.confirmReset = true;
                }
            }
        }
    }
}
