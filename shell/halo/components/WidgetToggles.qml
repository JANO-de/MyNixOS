import QtQuick
import qs.services

// Four quick toggles (same actions as the shade).
Item {
    id: root
    readonly property var ids: ["wifi", "bluetooth", "dnd", "rotation"]

    Grid {
        anchors.fill: parent
        columns: 2
        spacing: 8

        Repeater {
            model: root.ids

            Rectangle {
                id: t
                required property string modelData
                readonly property var inf: Controls.info(modelData)
                width: (root.width - 8) / 2
                height: (root.height - 8) / 2
                radius: 18
                color: inf.active ? Theme.accent : Qt.rgba(1, 1, 1, tma.pressed ? 0.24 : 0.12)

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 16
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: t.inf.title
                        color: t.inf.active ? Theme.accentInk : Theme.text
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: t.inf.sub
                        color: t.inf.active ? Theme.accentInkDim : Theme.dim
                        font.pixelSize: 11
                    }
                }
                MouseArea {
                    id: tma
                    anchors.fill: parent
                    onClicked: Controls.trigger(t.modelData)
                }
            }
        }
    }
}
