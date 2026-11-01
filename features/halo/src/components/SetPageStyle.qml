import QtQuick
import qs.services

// Settings > Wallpaper & style: theme, colours, wallpaper.
Column {
    id: page

    width: parent ? parent.width : 600
    spacing: 22

    function nameOf(spec) {
        const i = spec.indexOf(":");
        const v = spec.substring(i + 1);
        if (spec.startsWith("preset:"))
            return v.charAt(0).toUpperCase() + v.substring(1);
        return v.substring(v.lastIndexOf("/") + 1);
    }

    SetGroup {
        title: "Theme"
        SetRow {
            glyph: "◐"
            title: "Dark theme"
            subtitle: Theme.light ? "Off" : "On"
            onClicked: Theme.setLight(!Theme.light)

            SetSwitch {
                checked: !Theme.light
                onToggled: Theme.setLight(!Theme.light)
            }
        }
        SetDropdown {
            title: "Colour scheme"
            options: Theme.schemes
            current: Math.max(0, Theme.schemes.indexOf(Theme.scheme))
            onPicked: i => Theme.setScheme(Theme.schemes[i])
        }
    }

    SetGroup {
        title: "Wallpaper"

        Repeater {
            model: Wallpaper.specs

            SetRow {
                id: row

                required property string modelData

                title: page.nameOf(modelData)
                subtitle: modelData.startsWith("preset:") ? "Built-in" : "Picture"
                onClicked: Wallpaper.set(modelData)

                Text {
                    visible: Wallpaper.current === row.modelData
                    text: "✓"
                    color: Theme.accent
                    font.pixelSize: 22
                }
            }
        }
    }
}
