import QtQuick
import qs.services

// Centered glass sheet with a title and an X. Put content in as children (it scrolls if tall).
Rectangle {
    id: root

    property string title: ""
    default property alias content: body.data
    signal closed

    readonly property real maxH: parent ? parent.height - 120 : 600

    width: parent ? Math.min(parent.width - 48, 640) : 600
    height: Math.min(maxH, body.childrenRect.height + 96)
    radius: 36
    color: Qt.rgba(0.11, 0.19, 0.2, 0.97)
    border.color: Theme.glassStroke
    border.width: 1

    // Swallow taps so the backdrop does not close the sheet.
    MouseArea { anchors.fill: parent }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 28
        anchors.top: parent.top
        anchors.topMargin: 24
        text: root.title
        color: Theme.text
        font.pixelSize: 20
        font.weight: Font.DemiBold
    }

    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.top: parent.top
        anchors.topMargin: 18
        width: 36
        height: 36
        radius: 18
        color: Qt.rgba(1, 1, 1, 0.14)

        Text {
            anchors.centerIn: parent
            text: "✕"
            color: Theme.text
            font.pixelSize: 15
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            onClicked: root.closed()
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: 72
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.bottomMargin: 24
        clip: true
        contentWidth: width
        contentHeight: body.childrenRect.height
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: body
            width: parent.width
            height: childrenRect.height
        }
    }
}
