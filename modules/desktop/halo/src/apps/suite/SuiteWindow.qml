import QtQuick
import Quickshell
import qs.common

// Window shell for the Halo suite apps (Calculator, Clock, Calendar, Notes, ...): same chrome as Files.
// Title row (round back / close pills, actions on the right) over one rounded content panel (radius 32, AppTheme.low).
// The window title doubles as the app identity fallback (Apps.qml matches "halo-<title>").
FloatingWindow {
    id: root
    property string heading: title
    property bool canBack: false
    property alias actions: actionRow.data
    default property alias content: body.data
    signal backClicked

    color: AppTheme.bg
    implicitWidth: 1000
    implicitHeight: 720

    Item {
        anchors.fill: parent

        Item {
            id: bar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64

            Pill {
                id: backBtn
                visible: root.canBack
                icon: "back"
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.backClicked()
            }
            Text {
                anchors.left: backBtn.visible ? backBtn.right : parent.left
                anchors.leftMargin: backBtn.visible ? 10 : 22
                anchors.right: actionRow.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.heading
                color: AppTheme.text
                font.pixelSize: 24
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Row {
                id: actionRow
                anchors.right: closeBtn.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
            }
            Pill {
                id: closeBtn
                icon: "close"
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                onClicked: Qt.quit()
            }
        }

        Rectangle {
            id: body
            anchors.top: bar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.bottomMargin: 8
            radius: 32
            color: AppTheme.low
            clip: true
        }
    }
}
