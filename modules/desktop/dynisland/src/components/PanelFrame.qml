// Frame shared by every island panel: title + close button on top, content below.
// Usage:  PanelFrame { title: "Timer"; icon: "timer"; <your items here> }
import QtQuick
import qs.services

Item {
    id: f
    property string title: ""
    property string icon: ""
    default property alias content: body.data
    property alias body: body
    anchors.fill: parent

    Item {
        id: head; height: 44
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 8; leftMargin: 18; rightMargin: 12 }
        Row {
            anchors.verticalCenter: parent.verticalCenter; spacing: 10
            Icon { visible: f.icon !== ""; name: f.icon; size: 20; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
            Text { text: f.title; color: "white"; font.pixelSize: 16; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
        Rectangle {
            width: 30; height: 30; radius: 15; anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            color: cma.containsMouse ? "#33ffffff" : "#18ffffff"
            Icon { anchors.centerIn: parent; name: "close"; size: 18; color: "white" }
            MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true; onClicked: UiState.closePanel() }
        }
    }
    Item {
        id: body
        anchors { top: head.bottom; left: parent.left; right: parent.right; bottom: parent.bottom
                  topMargin: 4; leftMargin: 18; rightMargin: 18; bottomMargin: 16 }
    }
}
