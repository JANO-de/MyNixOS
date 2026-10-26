import QtQuick
import qs.services

// Settings: dropdown. A row showing the current value; tap to expand the options inline (SetRadio).
Column {
    id: root

    property string title: ""
    property var options: []
    property int current: 0
    property bool open: false
    signal picked(int index)

    width: parent ? parent.width : 600
    spacing: 3

    SetRow {
        title: root.title
        subtitle: root.options[root.current] || ""
        onClicked: root.open = !root.open

        Text {
            text: root.open ? "▴" : "▾"
            color: Theme.dim
            font.pixelSize: 18
        }
    }

    SetRadio {
        visible: root.open
        options: root.options
        current: root.current
        onPicked: i => {
            root.picked(i);
            root.open = false;
        }
    }
}
