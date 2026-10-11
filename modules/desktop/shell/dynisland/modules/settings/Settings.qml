// =============================================================================
//  Settings — centered overlay window (iNiR-style): sidebar + pages.
//  Open: the gear in the island, or `qs -c dynisland ipc call settings toggle`.
//  Close: Esc or the X.
//
//  TO ADD A PAGE: create FooPage.qml here, add an entry to `pages`.
// =============================================================================
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

PanelWindow {
    id: win
    visible: UiState.settingsOpen
    color: "transparent"
    implicitWidth: 1000; implicitHeight: 660            // no anchors => centered
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dynisland-settings"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property int page: 0
    readonly property var pages: [
        { name: "Appearance", icon: "palette",      comp: "AppearancePage.qml" },
        { name: "Island",     icon: "pill",         comp: "IslandPage.qml" },
        { name: "Visualizer", icon: "graphic_eq",   comp: "VisualizerPage.qml" },
        { name: "Dock",       icon: "dock_to_bottom", comp: "DockPage.qml" },
        { name: "Widgets",    icon: "widgets",      comp: "WidgetsPage.qml" }
    ]

    Rectangle {
        anchors.fill: parent; radius: 28; color: Theme.surface
        border.width: 1; border.color: Theme.outline
        focus: true
        Keys.onEscapePressed: UiState.settingsOpen = false

        // sidebar
        Rectangle {
            id: side; width: 220; anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            radius: 28; color: Theme.surfaceContainer
            Column {
                anchors { fill: parent; margins: 16; topMargin: 28 } spacing: 6
                Text { text: "Dynamic Island"; color: Theme.onSurface; font.pixelSize: 18; font.weight: Font.Bold; bottomPadding: 12 }
                Repeater {
                    model: win.pages
                    Rectangle {
                        required property var modelData
                        required property int index
                        width: parent.width; height: 42; radius: 21
                        color: win.page === index ? Theme.primary : (ma.containsMouse ? Theme.surfaceContainerHigh : "transparent")
                        Row {
                            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter } spacing: 10
                            Icon { name: modelData.icon; size: 20; color: win.page === index ? Theme.onPrimary : Theme.onSurface }
                            Text { text: modelData.name; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter
                                   color: win.page === index ? Theme.onPrimary : Theme.onSurface }
                        }
                        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: win.page = index }
                    }
                }
            }
        }

        // page area
        Loader {
            anchors { left: side.right; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 28 }
            source: win.pages[win.page].comp
        }

        IconButton { icon: "close"; diameter: 34; iconSize: 18; anchors { top: parent.top; right: parent.right; margins: 16 }
                     onClicked: UiState.settingsOpen = false }
    }
}
