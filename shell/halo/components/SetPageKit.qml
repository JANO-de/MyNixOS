import QtQuick
import qs.services

// DEV page: shows every Settings component (B2). Remove once B4 migrates the real pages.
Column {
    id: page

    property int radio: 1
    property int drop: 0
    property bool sw: true
    property real sl: 0.4
    property int chip: 0

    width: parent ? parent.width : 600
    spacing: 22

    SetGroup {
        title: "Search"
        SetSearch {}
    }
    SetGroup {
        title: "Rows and switch"
        SetRow {
            glyph: "◐"
            title: "Preference row"
            subtitle: "Title, summary and a switch"
            onClicked: page.sw = !page.sw
            SetSwitch { checked: page.sw; onToggled: page.sw = !page.sw }
        }
        SetRow { glyph: "≋"; title: "Row with chevron"; subtitle: "Opens a subpage"; chevron: true }
    }
    SetGroup {
        title: "Radio"
        SetRadio {
            options: ["Option A", "Option B", "Option C"]
            current: page.radio
            onPicked: i => page.radio = i
        }
    }
    SetGroup {
        title: "Dropdown"
        SetDropdown {
            title: "Dropdown"
            options: ["Never", "30 seconds", "1 minute", "5 minutes"]
            current: page.drop
            onPicked: i => page.drop = i
        }
    }
    SetGroup {
        title: "Slider and chips"
        QsSlider { width: parent.width; label: "Slider"; value: page.sl; onMoved: v => page.sl = v }
        SetChips { options: ["One", "Two", "Three"]; current: page.chip; onPicked: i => page.chip = i }
    }
    Item { width: 1; height: 500 } // makes the page scroll: tests the collapsing title
}
