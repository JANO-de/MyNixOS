// Notification history (everything the server still tracks). Click one to dismiss it.
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.components

PanelFrame {
    id: p
    title: "Notifications"; icon: "notifications"
    readonly property var items: Notifs.list.values.slice().reverse()   // newest first

    PillButton {
        parent: p; z: 5; label: "Clear all"; icon: "delete_sweep"; implicitHeight: 30; visible: p.items.length > 0
        anchors { top: parent.top; right: parent.right; topMargin: 15; rightMargin: 56 }
        onClicked: { Array.from(Notifs.list.values).forEach(n => n.dismiss()); Notifs.dismiss() }
    }
    Flickable {
        anchors.fill: parent; clip: true; contentHeight: hl.height; boundsBehavior: Flickable.StopAtBounds
        Column {
            id: hl; width: parent.width; spacing: 6
            Text { visible: p.items.length === 0; text: "No notifications"; color: "#77ffffff"; font.pixelSize: 13 }
            Repeater {
                model: p.items
                Rectangle {
                    required property var modelData
                    width: hl.width; height: hc.height + 20; radius: 16
                    color: hma.containsMouse ? "#22ffffff" : "#14ffffff"
                    ClippingRectangle {
                        id: hi; width: 36; height: 36; radius: 10; color: "#2a2a2a"
                        anchors { left: parent.left; leftMargin: 10; top: parent.top; topMargin: 10 }
                        Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; asynchronous: true
                                source: modelData.image || (modelData.appIcon ? Quickshell.iconPath(modelData.appIcon, "dialog-information") : "") }
                    }
                    Column {
                        id: hc
                        anchors { left: hi.right; right: parent.right; leftMargin: 10; rightMargin: 12; top: parent.top; topMargin: 10 }
                        spacing: 2
                        Text { width: parent.width; elide: Text.ElideRight; text: (modelData.appName ? modelData.appName + "  ·  " : "") + modelData.summary
                               color: "white"; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Text { width: parent.width; visible: modelData.body !== ""; maximumLineCount: 3; wrapMode: Text.WordWrap; elide: Text.ElideRight
                               text: modelData.body; color: "#bbffffff"; font.pixelSize: 12 }
                        Row {
                            spacing: 6; topPadding: modelData.actions && modelData.actions.length > 0 ? 4 : 0
                            Repeater {
                                model: modelData.actions ? modelData.actions.length : 0
                                Rectangle {
                                    required property int index
                                    readonly property var act: modelData.actions[index]
                                    width: al.implicitWidth + 20; height: 24; radius: 12; color: aa.containsMouse ? Theme.primary : "#2affffff"
                                    Text { id: al; anchors.centerIn: parent; text: parent.act ? parent.act.text : ""; font.pixelSize: 11
                                           color: aa.containsMouse ? Theme.primaryFg : "white" }
                                    MouseArea { id: aa; anchors.fill: parent; hoverEnabled: true
                                                onClicked: { if (parent.act) parent.act.invoke(); modelData.dismiss() } }
                                }
                            }
                        }
                    }
                    MouseArea { id: hma; anchors.fill: parent; hoverEnabled: true; z: -1; onClicked: modelData.dismiss() }
                }
            }
        }
    }
}
