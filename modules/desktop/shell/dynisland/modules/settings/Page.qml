// Scrollable page base: children are stacked vertically.
import QtQuick
import qs.services

Flickable {
    id: p
    default property alias content: col.data
    property string title: ""
    contentHeight: col.height + 20
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: col
        width: p.width - 24
        spacing: 4
        Text { text: p.title; color: Theme.surfaceFg; font.pixelSize: 24; font.weight: Font.Bold; bottomPadding: 10 }
    }
}
