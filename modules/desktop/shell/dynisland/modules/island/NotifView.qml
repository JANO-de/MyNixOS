// Notification banner inside the island. Click to dismiss.
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.components

Item {
    id: v
    property bool active: false
    readonly property var n: Notifs.current
    anchors.fill: parent
    opacity: active ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 150 } }

    ClippingRectangle {
        id: img; width: 52; height: 52; radius: 14; color: "#2a2a2a"
        anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
        Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; asynchronous: true
                source: v.n ? (v.n.image || (v.n.appIcon ? Quickshell.iconPath(v.n.appIcon, "dialog-information") : "")) : "" }
    }
    Column {
        anchors { left: img.right; right: parent.right; leftMargin: 14; rightMargin: 18; verticalCenter: parent.verticalCenter }
        spacing: 3
        Text { width: parent.width; elide: Text.ElideRight; color: "white"; font.pixelSize: 14; font.weight: Font.DemiBold
               text: v.n ? v.n.summary : "" }
        Text { width: parent.width; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap
               color: "#bbffffff"; font.pixelSize: 12; text: v.n ? v.n.body : "" }
    }
    MouseArea { anchors.fill: parent; onClicked: Notifs.dismiss() }
}
