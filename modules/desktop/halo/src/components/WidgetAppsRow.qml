import QtQuick
import qs.services

// Up to 4 chosen apps in a row (pick with the pencil).
Item {
    id: root
    property var inst: null
    readonly property var apps: inst && inst.cfg && inst.cfg.apps ? inst.cfg.apps : []

    Row {
        anchors.centerIn: parent
        spacing: 10
        visible: root.apps.length > 0

        Repeater {
            model: root.apps

            Item {
                id: cell
                required property string modelData
                readonly property var entry: Home.entry(modelData)
                width: Math.min(100, (root.width - 30) / 4)
                height: root.height

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(cell.width * 0.8, root.height * 0.55)
                        height: width
                        source: cell.entry ? Apps.iconSource(cell.entry.icon) : ""
                        sourceSize: Qt.size(128, 128)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                    Text {
                        width: cell.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: cell.entry ? cell.entry.name : ""
                        color: Theme.text
                        font.pixelSize: 11
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Home.launch(cell.entry)
                }
            }
        }
    }
    Text {
        anchors.centerIn: parent
        visible: root.apps.length === 0
        text: "Tap \u270e to choose apps"
        color: Theme.dim
        font.pixelSize: 13
    }
}
