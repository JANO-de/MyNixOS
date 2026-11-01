import QtQuick
import qs.services

// Settings > Display (AOSP order: brightness, auto-rotate, dark theme, display size, colours).
Column {
    id: page

    width: parent ? parent.width : 600
    spacing: 22

    Component.onCompleted: System.refresh()

    SetGroup {
        title: "Brightness level"
        QsSlider {
            width: parent.width
            label: "Brightness"
            value: System.brightness
            onMoved: v => System.setBrightness(v)
        }
    }

    SetGroup {
        SetRow {
            glyph: "⟲"
            title: "Auto-rotate screen"
            subtitle: System.rotationLocked ? "Off: orientation is locked" : "Follows the device orientation"
            onClicked: System.toggleRotationLock()

            SetSwitch {
                checked: !System.rotationLocked
                onToggled: System.toggleRotationLock()
            }
        }
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
    }

    SetGroup {
        title: "Display size"
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
        title: "Colours"
        SetDropdown {
            title: "Colour scheme"
            options: Theme.schemes
            current: Math.max(0, Theme.schemes.indexOf(Theme.scheme))
            onPicked: i => Theme.setScheme(Theme.schemes[i])
        }
    }

    SetGroup {
        SetRow {
            glyph: "▭"
            title: "Device mode"
            subtitle: Mode.tablet ? "Tablet (no keyboard attached)" : "Desktop (keyboard attached)"
            tappable: false
        }
    }
}
