import QtQuick
import qs.services

// Settings > Display: brightness, rotation lock, colour scheme (matugen), interface size.
Column {
    id: page

    width: parent ? parent.width : 600
    spacing: 22

    Component.onCompleted: System.refresh()

    SetGroup {
        title: "Brightness"
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
            title: "Lock rotation"
            subtitle: "Keep the screen in its current orientation"
            onClicked: System.toggleRotationLock()

            SetSwitch {
                checked: System.rotationLocked
                onToggled: System.toggleRotationLock()
            }
        }
        SetRow {
            glyph: "▭"
            title: "Mode"
            subtitle: Mode.tablet ? "Tablet (no keyboard attached)" : "Desktop (keyboard attached)"
            tappable: false
        }
    }

    SetGroup {
        title: "Colour scheme (from the wallpaper)"
        SetChips {
            options: Theme.schemes
            current: Math.max(0, Theme.schemes.indexOf(Theme.scheme))
            onPicked: i => Theme.setScheme(Theme.schemes[i])
        }
    }

    SetGroup {
        title: "Interface size"
        SetChips {
            options: ["Small", "Medium", "Large"]
            current: Home.density
            onPicked: i => {
                Home.density = i;
                Home.save();
            }
        }
    }
}
