import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Heads-up notification banner. Tap to dismiss.
PanelWindow {
    id: root

    readonly property bool active: Notifs.banner !== null && !UI.shadeOpen
    property var last: ({ app: "", summary: "", body: "" })

    onActiveChanged: if (active) last = Notifs.banner

    anchors.top: true
    margins.top: 14
    implicitWidth: 440
    implicitHeight: card.height + 20
    color: "transparent"
    visible: active || card.opacity > 0.01
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "halo-banner"
    WlrLayershell.layer: WlrLayer.Overlay

    Rectangle {
        id: card
        width: parent.width - 20
        height: col.implicitHeight + 28
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 24
        color: Qt.rgba(0.13, 0.13, 0.16, 0.8)
        border.color: Theme.glassStroke
        border.width: 1
        opacity: root.active ? 1 : 0
        y: root.active ? 0 : -height
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on y { NumberAnimation { duration: 340; easing.type: Easing.OutQuint } }

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 18
            spacing: 2

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.last.app
                color: Theme.dim
                font.pixelSize: 12
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.last.summary
                color: Theme.text
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
            Text {
                width: parent.width
                visible: text !== ""
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: root.last.body
                color: Theme.text
                opacity: 0.85
                font.pixelSize: 13
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Notifs.hideBanner()
        }
    }
}
