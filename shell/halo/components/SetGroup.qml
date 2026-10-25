import QtQuick
import qs.services

// Settings: a titled card holding rows (SetRow, sliders, chips...).
Column {
    id: root

    property string title: ""
    default property alias content: inner.data

    width: parent ? parent.width : 600
    spacing: 8

    Text {
        visible: root.title !== ""
        leftPadding: 8
        text: root.title
        color: Theme.dim
        font.pixelSize: 14
        font.weight: Font.DemiBold
    }

    Column {
        id: inner
        width: parent.width
        spacing: 3
    }
}
