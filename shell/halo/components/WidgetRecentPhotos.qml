import QtQuick
import Quickshell
import qs.services

// Recent photos: the 4 newest pictures (Pics.qml); tap opens the Gallery.
Item {
    id: root
    property var inst: null
    readonly property var list: Pics.files.slice(0, 4)

    Row {
        anchors.fill: parent
        spacing: 6
        Repeater {
            model: root.list
            Image {
                required property string modelData
                width: (root.width - 18) / 4
                height: root.height
                source: "file://" + modelData
                sourceSize: Qt.size(240, 240)
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
            }
        }
    }
    Text {
        visible: root.list.length === 0
        anchors.centerIn: parent
        text: "No photos yet"
        color: Theme.dim
        font.pixelSize: 13
    }
    MouseArea {
        anchors.fill: parent
        enabled: !Home.editing
        onClicked: Home.launch(DesktopEntries.heuristicLookup("halo-gallery"))
    }
}
