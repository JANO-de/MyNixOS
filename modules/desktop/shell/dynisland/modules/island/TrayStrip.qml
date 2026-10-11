// =============================================================================
//  TrayStrip — status-notifier (tray) icons inside the expanded island.
//    left click   : activate (or open the menu if the app is menu-only)
//    right click  : opens the app's menu INSIDE the island (see TrayMenuView.qml)
//    middle click : secondary action
//  Hidden when there are no tray icons.
// =============================================================================
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.services

Row {
    id: strip
    spacing: 8
    visible: SystemTray.items.values.length > 0
    height: 22

    Repeater {
        model: SystemTray.items
        Item {
            id: cell
            required property var modelData   // SystemTrayItem
            width: 22; height: 22
            opacity: ma.containsMouse ? 1 : 0.85

            Image {
                anchors.fill: parent
                source: cell.modelData.icon
                sourceSize: Qt.size(44, 44); smooth: true; mipmap: true
            }
            MouseArea {
                id: ma
                anchors.fill: parent; hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onClicked: mouse => {
                    const t = cell.modelData;
                    if (mouse.button === Qt.MiddleButton) { t.secondaryActivate(); return }
                    if (mouse.button === Qt.RightButton || t.onlyMenu) {
                        if (t.hasMenu) { UiState.trayTitle = t.title || t.tooltipTitle || t.id; UiState.trayStack = [t.menu] }
                        return
                    }
                    t.activate();
                }
            }
        }
    }
}
