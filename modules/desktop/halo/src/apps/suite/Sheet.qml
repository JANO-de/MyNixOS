import QtQuick
import qs.common

// Modal dialog over the window content (scrim + rounded card, scrolls when the window is short).
//   Sheet { open: win.creating; title: "New event"; onClosed: win.creating = false; <children stack vertically> }
Rectangle {
    id: sh
    property bool open: false
    property string title: ""
    property real cardWidth: 520
    default property alias content: col.data
    signal closed

    anchors.fill: parent
    z: 50
    color: Qt.rgba(0, 0, 0, 0.5)
    opacity: open ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 160 } }

    MouseArea {
        anchors.fill: parent
        enabled: sh.open
        onClicked: sh.closed()
    }
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(sh.width - 32, sh.cardWidth)
        height: Math.min(sh.height - 32, 74 + col.height + 22)
        radius: 32
        color: AppTheme.cardHigh
        border.width: 1
        border.color: AppTheme.line
        scale: sh.open ? 1 : 0.94
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

        MouseArea { anchors.fill: parent }   // swallow taps on the card

        Text {
            x: 28
            y: 24
            text: sh.title
            color: AppTheme.text
            font.pixelSize: 22
            font.weight: Font.DemiBold
        }
        Flickable {
            anchors.top: parent.top
            anchors.topMargin: 70
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 22
            contentWidth: width
            contentHeight: col.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: col
                width: parent.width
                spacing: 12
            }
        }
    }
}
