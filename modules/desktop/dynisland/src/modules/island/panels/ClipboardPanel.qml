// Clipboard history (cliphist). Click an entry to copy it again, X to delete it.
import QtQuick
import qs.services
import qs.components

PanelFrame {
    id: p
    title: "Clipboard"; icon: "content_paste"
    Component.onCompleted: Clip.refresh()

    PillButton {
        parent: p; z: 5; label: "Clear all"; icon: "delete_sweep"; implicitHeight: 30; visible: Clip.items.length > 0
        anchors { top: parent.top; right: parent.right; topMargin: 15; rightMargin: 56 }
        onClicked: Clip.wipe()
    }
    Flickable {
        anchors.fill: parent; clip: true; contentHeight: cl.height; boundsBehavior: Flickable.StopAtBounds
        Column {
            id: cl; width: parent.width; spacing: 5
            Text { visible: Clip.items.length === 0; text: "Clipboard history is empty"; color: "#77ffffff"; font.pixelSize: 13 }
            Repeater {
                model: Clip.items
                Rectangle {
                    required property var modelData
                    width: cl.width; height: 40; radius: 14
                    color: ma.containsMouse ? "#22ffffff" : "#14ffffff"
                    Icon { id: ic; name: modelData.image ? "image" : "notes"; size: 18; color: "#bbffffff"
                           anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter } }
                    Text {
                        anchors { left: ic.right; right: x.left; leftMargin: 10; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        elide: Text.ElideRight; maximumLineCount: 1; color: "white"; font.pixelSize: 12
                        text: modelData.image ? "Image" : modelData.text
                    }
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: { Clip.copy(modelData.id); UiState.closePanel() } }
                    Icon { id: x; name: "close"; size: 16; color: xa.containsMouse ? "white" : "#88ffffff"
                           anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                           MouseArea { id: xa; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; onClicked: Clip.remove(modelData.id) } }
                }
            }
        }
    }
}
