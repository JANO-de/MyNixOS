import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Visual feedback while an app is dragged up out of the dock: the app icon follows the finger and the
// target is shown (edge = Slide Over, further in = Split View). The touch stays grabbed by the dock
// window; this window only draws, so it takes no input.
PanelWindow {
    id: root

    readonly property string zone: UI.dockDragZone
    readonly property bool isSlide: zone.indexOf("slide") === 0
    readonly property bool isLeft: zone.indexOf("left") >= 0

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    visible: UI.dockDragActive && UI.dockDragScreen === (screen ? screen.name : "")
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    WlrLayershell.namespace: "halo-dockdrag"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.28)
    }

    // Target preview
    Rectangle {
        visible: root.zone !== ""
        width: root.isSlide ? 420 : root.width / 2 - 20
        height: root.isSlide ? root.height * 0.86 : root.height - 40
        y: (root.height - height) / 2
        x: root.isLeft ? (root.isSlide ? 16 : 10) : root.width - width - (root.isSlide ? 16 : 10)
        radius: 32
        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
        border.color: Theme.accent
        border.width: 3

        Text {
            anchors.centerIn: parent
            text: root.isSlide ? "Slide Over" : "Split View"
            color: Theme.text
            font.pixelSize: 26
            font.weight: Font.DemiBold
        }
    }

    // Hint while no zone is hit
    Rectangle {
        visible: root.zone === ""
        anchors.horizontalCenter: parent.horizontalCenter
        y: 48
        width: hint.implicitWidth + 40
        height: 44
        radius: 22
        color: Theme.glass
        border.color: Theme.glassStroke
        border.width: 1

        Text {
            id: hint
            anchors.centerIn: parent
            text: "Edge: Slide Over  ·  Further in: Split View"
            color: Theme.text
            font.pixelSize: 15
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
