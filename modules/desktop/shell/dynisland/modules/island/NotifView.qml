// Notification banner inside the island. Click to dismiss.
// If the notification has actions (Reply, Open, ...) they show as buttons below.
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.components

Item {
    id: v
    property bool active: false
    readonly property var n: Notifs.current
    readonly property int nActions: n && n.actions ? Math.min(n.actions.length, 3) : 0
    readonly property real lift: nActions > 0 ? -20 : 0     // content moves up to make room
    anchors.fill: parent
    opacity: active ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    // behind everything: click anywhere dismisses (buttons sit above and take their own clicks)
    MouseArea { anchors.fill: parent; onClicked: Notifs.dismiss() }

    ClippingRectangle {
        id: img; width: 52; height: 52; radius: 14; color: "#2a2a2a"
        anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter; verticalCenterOffset: v.lift }
        Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; asynchronous: true
                source: v.n ? (v.n.image || (v.n.appIcon ? Quickshell.iconPath(v.n.appIcon, "dialog-information") : "")) : "" }
    }
    Column {
        anchors { left: img.right; right: parent.right; leftMargin: 14; rightMargin: 18; verticalCenter: parent.verticalCenter; verticalCenterOffset: v.lift }
        spacing: 3
        Text { width: parent.width; elide: Text.ElideRight; color: "white"; font.pixelSize: 14; font.weight: Font.DemiBold
               text: v.n ? v.n.summary : "" }
        Text { width: parent.width; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap
               color: "#bbffffff"; font.pixelSize: 12; text: v.n ? v.n.body : "" }
    }

    // action buttons
    Row {
        visible: v.nActions > 0
        anchors { left: parent.left; leftMargin: 18; bottom: parent.bottom; bottomMargin: 12 }
        spacing: 8
        Repeater {
            model: v.nActions
            Rectangle {
                required property int index
                readonly property var act: v.n ? v.n.actions[index] : null
                width: albl.implicitWidth + 28; height: 28; radius: 14
                color: abtn.pressed ? Theme.primary : "#2affffff"
                Text { id: albl; anchors.centerIn: parent; font.pixelSize: 12
                       color: abtn.pressed ? Theme.primaryFg : "white"; text: parent.act ? parent.act.text : "" }
                MouseArea { id: abtn; anchors.fill: parent; onClicked: { if (parent.act) parent.act.invoke(); Notifs.dismiss() } }
            }
        }
    }
}
