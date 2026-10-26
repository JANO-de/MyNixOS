import QtQuick
import qs.services

// DEV subpage opened from the kit page (B3 navigation test).
Column {
    width: parent ? parent.width : 600
    spacing: 22

    SetGroup {
        title: "Subpage"
        SetRow { glyph: "‹"; title: "Back works"; subtitle: "Arrow in the header, back gesture, or Back key"; tappable: false }
    }
    Item { width: 1; height: 500 }
}
