// =============================================================================
//  Wallpaper — drawn by the shell itself (no swww/swaybg needed) with a
//  crossfade. Source: Config.appearance.wallpaper.
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

    Image { id: back; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; asynchronous: true
            sourceSize.width: win.width; sourceSize.height: win.height }
    Image {
        id: front; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; asynchronous: true
        source: win.current ? "file://" + win.current : ""
        sourceSize.width: win.width; sourceSize.height: win.height
        opacity: 0
        onStatusChanged: if (status === Image.Ready) fade.restart()
    }
    NumberAnimation { id: fade; target: front; property: "opacity"; to: 1; duration: 600; easing.type: Easing.OutCubic }
}
