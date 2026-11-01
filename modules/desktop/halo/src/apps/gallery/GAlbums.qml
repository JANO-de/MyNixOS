import QtQuick
import qs.common

// iPad-style Albums page: Recents, Favorites, Videos, one card per folder, Recently Deleted.
Item {
    id: a
    property var host
    readonly property real pad: 16
    readonly property real gap: 14
    readonly property int n: Math.max(2, Math.floor((width - 2 * pad) / 230))
    readonly property real cw: Math.floor((width - 2 * pad - (n - 1) * gap) / n)

    GridView {
        anchors.fill: parent
        anchors.leftMargin: a.pad
        anchors.rightMargin: a.pad
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        cellWidth: a.cw + a.gap
        cellHeight: a.cw + 60
        model: a.host.albumCards
        delegate: Item {
            id: card
            required property var modelData
            width: a.cw
            height: a.cw + 50
            readonly property string ico: modelData.kind === "favs" ? "heart" : (modelData.kind === "videos" ? "video" : (modelData.kind === "trash" ? "trash" : (modelData.kind === "library" ? "image" : "folder")))

            Rectangle {
                id: cover
                width: parent.width
                height: a.cw
                radius: 22
                color: AppTheme.card
                scale: cm.pressed ? 0.96 : 1
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                Ico { anchors.centerIn: parent; name: card.ico; size: a.cw * 0.3; color: AppTheme.dim }
                RoundImg {
                    visible: card.modelData.cover !== null
                    anchors.fill: parent
                    radius: 22
                    px: 360
                    source: card.modelData.cover ? a.host.srcOf(card.modelData.cover) : ""
                }
                MouseArea { id: cm; anchors.fill: parent; onClicked: a.host.openCard(card.modelData) }
            }
            Text {
                anchors.top: cover.bottom
                anchors.topMargin: 8
                width: parent.width
                text: card.modelData.name
                elide: Text.ElideRight
                color: AppTheme.text
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }
            Text {
                anchors.top: cover.bottom
                anchors.topMargin: 29
                width: parent.width
                text: card.modelData.count
                color: AppTheme.dim
                font.pixelSize: 14
            }
        }
    }
}
