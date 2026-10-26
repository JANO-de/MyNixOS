import QtQuick
import qs.services

// Settings > Accessibility: text size and motion.
Column {
    id: page

    width: parent ? parent.width : 600
    spacing: 22

    SetGroup {
        title: "Text and display"
        SetRow {
            glyph: "A"
            title: "Display size"
            subtitle: ["Small", "Default", "Large"][Home.density]
            tappable: false
        }
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
        SetRow {
            glyph: "motion"
            title: "Reduce motion"
            subtitle: UI.reduceMotion ? "On" : "Off"
            onClicked: UI.reduceMotion = !UI.reduceMotion

            SetSwitch {
                checked: UI.reduceMotion
                onToggled: UI.reduceMotion = !UI.reduceMotion
            }
        }
    }
}
