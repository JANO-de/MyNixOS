import QtQuick
import qs.services

// One app as a big tile: tap to open. Pick the app with the pencil in edit mode.
Item {
    id: root
    property var inst: null
    readonly property var apps: inst && inst.cfg && inst.cfg.apps ? inst.cfg.apps : []
    readonly property var entry: apps.length > 0 ? Home.entry(apps[0]) : null
    readonly property real s: Math.min(width, height)

    Column {
        anchors.centerIn: parent
        spacing: 6
        visible: root.entry !== null && root.entry !== undefined

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.s * 0.62
            height: width
            source: root.entry ? Apps.iconSource(root.entry.icon) : ""
            sourceSize: Qt.size(192, 192)
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
        Text {
            width: root.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.entry ? root.entry.name : ""
            color: Theme.text
            font.pixelSize: Math.max(11, root.s * 0.1)
        }
    }
    Text {
        anchors.centerIn: parent
        width: parent.width
        visible: !root.entry
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: "Tap \u270e to choose an app"
        color: Theme.dim
        font.pixelSize: 13
    }
    MouseArea {
        anchors.fill: parent
        enabled: root.entry !== null && root.entry !== undefined
        onClicked: Home.launch(root.entry)
    }
}
