import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Visual feedback while an app is dragged up out of the dock: the app icon follows the finger and the
// two half-screen drop targets are shown (Android split screen). The touch stays grabbed by the dock
// window; this window only draws, so it takes no input.
PanelWindow {
    id: root

    property string screenName: "" // plain string: reading `screen` inside `visible` makes a binding loop
    readonly property string zone: UI.dockDragZone
    
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    visible: UI.dockDragActive && UI.dockDragScreen === screenName
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    WlrLayershell.namespace: "halo-dockdrag"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.28)
    }

    // Android split drop targets: two half-screen panels above the dock; the one under the finger lights up.
    Repeater {
        model: ["split-left", "split-right"]

        Rectangle {
            id: target
            required property string modelData
            readonly property bool hot: root.zone === modelData
            readonly property bool isLeft: modelData === "split-left"

            x: isLeft ? 12 : root.width / 2 + 6
            y: 12
            width: root.width / 2 - 18
            height: root.height - UI.dockRect.height - 40
            radius: 28
            color: hot ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.30) : Qt.rgba(1, 1, 1, 0.08)
            border.color: hot ? Theme.accent : Qt.rgba(1, 1, 1, 0.22)
            border.width: hot ? 3 : 1
            scale: hot ? 1 : 0.98
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on scale { NumberAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: target.isLeft ? "Left" : "Right"
                visible: target.hot
                color: Theme.text
                font.pixelSize: 24
                font.weight: Font.DemiBold
            }
        }
    }

    // The dragged app
    Item {
        x: UI.dockDragX - 40
        y: UI.dockDragY - 40
        width: 80
        height: 80
        scale: 1.15

        Rectangle {
            visible: Theme.themedIcons
            anchors.fill: parent
            radius: width / 4
            color: Theme.iconTile
        }
        Image {
            anchors.centerIn: parent
            width: parent.width * (Theme.themedIcons ? 0.7 : 1)
            height: width
            source: Apps.iconSource(UI.dockDragIcon)
            sourceSize: Qt.size(160, 160)
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    }
}
