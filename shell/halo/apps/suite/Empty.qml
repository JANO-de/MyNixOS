import QtQuick
import qs.common

// Empty / loading state: big dim line icon + one line. Place it with anchors.centerIn: parent.
Item {
    id: e
    property string icon: ""
    property string text: ""
    width: 320
    height: col.height

    Column {
        id: col
        width: parent.width
        spacing: 12
        Item {
            width: parent.width
            height: 64
            Ico {
                anchors.centerIn: parent
                name: e.icon
                size: 64
                color: AppTheme.dim
                opacity: 0.6
            }
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: e.text
            color: AppTheme.dim
            font.pixelSize: 17
        }
    }
}
