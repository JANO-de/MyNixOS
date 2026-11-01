import QtQuick
import qs.common
import Quickshell

// Window shell shared by Halo apps: title row (optional back button, actions, close) over a content area.
// The window title doubles as the app identity fallback (Apps.qml matches "halo-<title>").
FloatingWindow {
    id: root
    property string heading: title
    property bool canBack: false
    property alias actions: actionRow.data
    default property alias content: body.data
    signal backClicked

    color: AppTheme.bg
    implicitWidth: 1100
    implicitHeight: 720

    Item {
        anchors.fill: parent

        Item {
            id: bar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 60

            Rectangle {
                id: back
                visible: root.canBack
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 44
                radius: 22
                color: AppTheme.card
                Text { anchors.centerIn: parent; text: "\u2039"; color: AppTheme.text; font.pixelSize: 30 }
                MouseArea { anchors.fill: parent; onClicked: root.backClicked() }
            }
            Text {
                anchors.left: back.visible ? back.right : parent.left
                anchors.leftMargin: 16
                anchors.right: actionRow.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.heading
                color: AppTheme.text
                font.pixelSize: 22
                font.weight: Font.DemiBold
                elide: Text.ElideMiddle
            }
            Row {
                id: actionRow
                anchors.right: closeBtn.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
            }
            Rectangle {
                id: closeBtn
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 44
                radius: 22
                color: AppTheme.card
                Text { anchors.centerIn: parent; text: "\u2715"; color: AppTheme.text; font.pixelSize: 18 }
                MouseArea { anchors.fill: parent; onClicked: Qt.quit() }
            }
        }
        Item {
            id: body
            anchors.top: bar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
        }
    }
}
