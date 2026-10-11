// =============================================================================
//  Wallpaper — drawn by the shell itself (no swww/swaybg needed) with a
//  crossfade. Source: Config.appearance.wallpaper. Fill mode + dim from Settings.
//  Right-click on the empty desktop opens DesktopMenu.qml.
// =============================================================================
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: win
    required property var modelData
    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "dynisland-wallpaper"
    color: Theme.surface

    readonly property string current: Config.appearance.wallpaper
    onCurrentChanged: {
        back.source = front.source;   // old image stays underneath while the new one fades in
        front.opacity = 0;
        front.source = current ? "file://" + current : "";
    }

    readonly property int fill: Config.appearance.wallpaperFill === "fit" ? Image.PreserveAspectFit
                              : Config.appearance.wallpaperFill === "stretch" ? Image.Stretch : Image.PreserveAspectCrop

    Image { id: back; anchors.fill: parent; fillMode: win.fill; asynchronous: true
            sourceSize.width: win.width; sourceSize.height: win.height }
    Image {
        id: front; anchors.fill: parent; fillMode: win.fill; asynchronous: true
        source: win.current ? "file://" + win.current : ""
        sourceSize.width: win.width; sourceSize.height: win.height
        opacity: 0
        onStatusChanged: if (status === Image.Ready) fade.restart()
    }
    NumberAnimation { id: fade; target: front; property: "opacity"; to: 1; duration: 600; easing.type: Easing.OutCubic }

    Rectangle { anchors.fill: parent; color: "black"; opacity: Config.appearance.wallpaperDim }   // dim overlay

    MouseArea {
        anchors.fill: parent; acceptedButtons: Qt.RightButton
        onClicked: mouse => {
            UiState.deskMenuScreen = win.screen.name;
            UiState.deskMenuX = mouse.x; UiState.deskMenuY = mouse.y;
            UiState.deskMenuOpen = true;
        }
    }
}
