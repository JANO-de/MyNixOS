import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Split select staging (Android: first app staged, pick the second). The staged app is shown as a
// half-screen placeholder on its side; the rest of the screen stays usable (only the cancel button takes touch).
PanelWindow {
    id: root

    property string screenName: "" // plain string: reading `screen` inside `visible` makes a binding loop
    readonly property bool isLeft: UI.stageSide === "left"

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    visible: UI.splitStaging && UI.stageScreenName === screenName
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: cancelBtn }

    WlrLayershell.namespace: "halo-splitstage"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Placeholder for the staged app (visual only).
    Rectangle {
        x: root.isLeft ? 12 : root.width / 2 + 6
        y: 12
        width: root.width / 2 - 18
        height: root.height - UI.dockRect.height - 40
        radius: 28
        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
        border.color: Theme.accent
        border.width: 2

        Item {
            anchors.centerIn: parent
            width: 96
            height: 96

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
                source: UI.stageItem ? Apps.iconSource(UI.stageItem.icon) : ""
                sourceSize: Qt.size(192, 192)
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }
    }

    // Instruction pill with the cancel button.
    Rectangle {
        id: pillBox
        anchors.horizontalCenter: parent.horizontalCenter
        y: 56
        width: msg.implicitWidth + cancelBtn.width + 44
        height: 44
        radius: 22
        color: Theme.glass
        border.color: Theme.glassStroke
        border.width: 1

        Text {
            id: msg
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: "Tap another app to use split screen"
            color: Theme.text
            font.pixelSize: 15
        }

        Rectangle {
            id: cancelBtn
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            radius: 16
            color: cancelArea.pressed ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(1, 1, 1, 0.14)

            Text {
                anchors.centerIn: parent
                text: "\u2715"
                color: Theme.text
                font.pixelSize: 14
            }
            MouseArea {
                id: cancelArea
                anchors.fill: parent
                anchors.margins: -6
                onClicked: UI.cancelSplitSelect()
            }
        }
    }
}
