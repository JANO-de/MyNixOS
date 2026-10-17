// Quick-settings pulldown: the controls card in its own window, independent of the island.
// Toggle: `qs -c dynisland ipc call quick toggle` (bind it in niri). Click outside to close.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: win
    visible: UiState.quickOpen && Config.system.quickPull
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dynisland-quick"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    onVisibleChanged: if (visible) Sys.watching = true

    MouseArea { anchors.fill: parent; onClicked: UiState.quickOpen = false }

    Rectangle {
        id: card
        width: 300; height: 270; radius: 30
        anchors.horizontalCenter: parent.horizontalCenter
        y: win.visible ? 14 : -height
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        color: "#f2101014"; border.width: 1; border.color: "#33ffffff"
        MouseArea { anchors.fill: parent }          // swallow clicks inside the card
        ControlsCard { anchors { fill: parent; margins: 18 } }
    }
}
