// =============================================================================
//  TrayMenuView — an app's tray menu drawn INSIDE the island ("tray" mode).
//  The pill morphs to fit it, so it keeps the island's look (black, glow, radius).
//  Submenus push onto UiState.trayStack; the header button goes Back / closes.
//  Closes on: entry click, header ✕, or a click anywhere outside (Island.qml).
// =============================================================================
import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

Item {
    id: v
    property bool active: false
    anchors.fill: parent
    opacity: active ? 1 : 0
    visible: opacity > 0.01
    scale: active ? 1 : 0.95   // content settles in as the pill morphs
    Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    // ---- header: back / close + app name
    Item {
        id: head; height: 36
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 10; leftMargin: 16; rightMargin: 16 }
        Rectangle {
            id: hb; width: 28; height: 28; radius: 14; anchors.verticalCenter: parent.verticalCenter
            color: hma.containsMouse ? "#33ffffff" : "#18ffffff"
            Icon { anchors.centerIn: parent; size: 18; color: "white"
                   name: UiState.trayStack.length > 1 ? "chevron_left" : "close" }
            MouseArea {
                id: hma; anchors.fill: parent; hoverEnabled: true
                onClicked: UiState.trayStack = UiState.trayStack.length > 1 ? UiState.trayStack.slice(0, -1) : []
            }
        }
        Text {
            anchors { left: hb.right; leftMargin: 10; right: parent.right; verticalCenter: parent.verticalCenter }
            text: UiState.trayTitle; color: "white"; font.pixelSize: 14; font.weight: Font.DemiBold; elide: Text.ElideRight
        }
    }

    // ---- entries
    Flickable {
        anchors { top: head.bottom; left: parent.left; right: parent.right; bottom: parent.bottom
                  topMargin: 4; leftMargin: 12; rightMargin: 12; bottomMargin: 12 }
        contentHeight: col.height; clip: true; boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width; spacing: 0
            Repeater {
                model: UiState.trayEntries   // QsMenuEntry: text, isSeparator, enabled, hasChildren, buttonType, checkState, triggered()
                Rectangle {
                    required property var modelData
                    readonly property bool sep: modelData.isSeparator
                    width: col.width; height: sep ? 9 : 32; radius: 12
                    color: !sep && modelData.enabled && ema.containsMouse ? "#22ffffff" : "transparent"
                    Behavior on color { ColorAnimation { duration: 90 } }

                    Rectangle { visible: parent.sep; anchors.centerIn: parent; width: parent.width - 20; height: 1; color: "#22ffffff" }
                    Icon {   // check / radio mark
                        visible: !parent.sep && modelData.buttonType !== 0 && modelData.checkState === Qt.Checked
                        name: "check"; size: 16; color: Theme.primary
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 8 }
                    }
                    Text {
                        visible: !parent.sep
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right
                                  leftMargin: 30; rightMargin: modelData.hasChildren ? 30 : 12 }
                        text: (modelData.text || "").replace(/_([^_])/g, "$1")   // strip GTK mnemonics
                        elide: Text.ElideRight; font.pixelSize: 13
                        color: "white"; opacity: modelData.enabled ? 1 : 0.35
                    }
                    Icon {   // submenu arrow
                        visible: !parent.sep && modelData.hasChildren
                        name: "chevron_right"; size: 18; color: "#aaffffff"
                        anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: 8 }
                    }
                    MouseArea {
                        id: ema; anchors.fill: parent; hoverEnabled: true; enabled: !parent.sep && modelData.enabled
                        onClicked: {
                            if (modelData.hasChildren) UiState.trayStack = UiState.trayStack.concat([modelData]);
                            else { modelData.triggered(); UiState.trayStack = [] }
                        }
                    }
                }
            }
        }
    }
}
