import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Recent files: last files opened from the Files app (~/.cache/halo/recent-files). Tap a row to open it; header opens Files.
Item {
    id: root
    property var inst: null
    property var files: []

    FileView {
        path: Quickshell.env("HOME") + "/.cache/halo/recent-files"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.files = text().trim() === "" ? [] : text().trim().split("\n").slice(0, 5)
    }

    Text {
        id: head
        text: "Recent files"
        color: Theme.accent
        font.pixelSize: 15
        font.weight: Font.DemiBold
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            enabled: !Home.editing
            onClicked: Home.launch(DesktopEntries.heuristicLookup("halo-files"))
        }
    }
    Column {
        anchors.top: head.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 4
        Repeater {
            model: root.files
            Item {
                required property string modelData
                width: root.width
                height: 30
                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: parent.modelData.substring(parent.modelData.lastIndexOf("/") + 1)
                    color: Theme.text
                    font.pixelSize: 14
                    elide: Text.ElideMiddle
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !Home.editing
                    onClicked: Quickshell.execDetached(["xdg-open", parent.modelData])
                }
            }
        }
    }
    Text {
        visible: root.files.length === 0
        anchors.centerIn: parent
        text: "Files you open show up here"
        color: Theme.dim
        font.pixelSize: 13
    }
}
