// =============================================================================
//  Settings — centered overlay window (iNiR-style): sidebar + pages + action bar.
//  Open: the gear in the island, desktop right-click > Open settings, or
//        `qs -c dynisland ipc call settings toggle`.
//
//  Changes apply LIVE as a preview but stay in memory while this window is open.
//    Save    writes them to ~/.config/dynisland/config.json
//    Discard reverts to the saved file
//    Reload  restarts the whole shell
//  Closing with unsaved changes (X / Esc) asks what to do. Closing any other way
//  (IPC toggle, gear) saves them, so nothing is lost silently.
//
//  TO ADD A PAGE: create FooPage.qml here, add an entry to `pages`.
// =============================================================================
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

PanelWindow {
    id: win
    visible: UiState.settingsOpen
    color: "transparent"
    implicitWidth: 1000; implicitHeight: 680            // no anchors => centered
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dynisland-settings"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // while open, Config keeps changes in memory (Save / Discard)
    Binding { target: Config; property: "hold"; value: UiState.settingsOpen }
    onVisibleChanged: { if (!visible) { confirm = false; if (Config.dirty) Config.save() } }

    property int page: 0
    readonly property int profilePage: pages.findIndex(p => p.hidden)
    property bool confirm: false          // "unsaved changes" prompt after X / Esc
    function requestClose() { if (Config.dirty) confirm = true; else UiState.settingsOpen = false }

    readonly property var pages: [
        { name: "Appearance", icon: "palette",        comp: "AppearancePage.qml" },
        { name: "WM",         icon: "window",         comp: "WMPage.qml" },
        { name: "Island",     icon: "pill",           comp: "IslandPage.qml" },
        { name: "Visualizer", icon: "graphic_eq",     comp: "VisualizerPage.qml" },
        { name: "Dock",       icon: "dock_to_bottom", comp: "DockPage.qml" },
        { name: "Widgets",    icon: "widgets",        comp: "WidgetsPage.qml" },
        { name: "Lock screen", icon: "lock",          comp: "LockPage.qml" },
        { name: "Calendar",   icon: "calendar_month", comp: "CalendarPage.qml" },
        { name: "Server",     icon: "dns",            comp: "ServerPage.qml" },
        { name: "System",     icon: "terminal",       comp: "SystemPage.qml" },
        { name: "AI",         icon: "smart_toy",      comp: "AIPage.qml" },
        { name: "Profile",    icon: "person",         comp: "ProfilePage.qml", hidden: true }   // opened from the sidebar header
    ]

    Rectangle {
        anchors.fill: parent; radius: 28 + Glass.radiusBoost; color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.95)
        border.width: 1; border.color: Glass.outline
        Rectangle { anchors.fill: parent; radius: parent.radius
                    gradient: Gradient { GradientStop { position: 0; color: Glass.sheenTop } GradientStop { position: 0.4; color: "transparent" } } }
        focus: true
        Keys.onEscapePressed: win.requestClose()

        // ---- sidebar
        Rectangle {
            id: side; width: 220; anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            radius: 28; color: "transparent"
            Rectangle { width: 1; anchors { top: parent.top; bottom: parent.bottom; right: parent.right; topMargin: 24; bottomMargin: 24 }
                        color: Theme.outline; opacity: 0.3 }   // flat sidebar, hairline separator
            Flickable {
                id: sideFl
                anchors { fill: parent; margins: 16; topMargin: 28 }
                contentHeight: col.height; clip: true
                boundsBehavior: Flickable.StopAtBounds
                Behavior on contentY { enabled: !sideFl.moving; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: e => { const d = e.angleDelta.y || e.angleDelta.x
                        sideFl.contentY = Math.max(0, Math.min(Math.max(0, sideFl.contentHeight - sideFl.height), sideFl.contentY - d / 2)) }
                }
            Column {
                id: col
                width: parent.width; spacing: 6
                Item {   // profile row: click opens the Profile page
                    width: parent.width; height: 76
                    Rectangle {
                        width: parent.width; height: 64; radius: 22
                        color: win.page === win.profilePage ? Theme.surfaceContainerHigh : (hma.containsMouse ? Theme.surfaceContainerHigh : "transparent")
                        border.width: win.page === win.profilePage ? 1 : 0; border.color: Theme.primary
                        ClippingRectangle {
                            id: hAv; width: 44; height: 44; radius: 22; color: Theme.primary
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            Image { anchors.fill: parent; visible: Config.profile.avatar !== ""; asynchronous: true
                                    source: Config.profile.avatar !== "" ? "file://" + Config.profile.avatar : ""
                                    fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(96, 96) }
                            Icon { visible: Config.profile.avatar === ""; anchors.centerIn: parent; name: "person"; size: 26; color: Theme.primaryFg }
                        }
                        Column {
                            anchors { left: hAv.right; leftMargin: 10; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            Text { width: parent.width; elide: Text.ElideRight; color: Theme.surfaceFg; font.pixelSize: 15; font.weight: Font.Bold
                                   text: Config.profile.name !== "" ? Config.profile.name : Quickshell.env("USER") }
                            Text { width: parent.width; elide: Text.ElideRight; color: Theme.surfaceFgDim; font.pixelSize: 12
                                   visible: text !== ""; text: Config.profile.description }
                        }
                        MouseArea { id: hma; anchors.fill: parent; hoverEnabled: true; onClicked: win.page = win.profilePage }
                    }
                }
                Repeater {
                    model: win.pages
                    Rectangle {
                        required property var modelData
                        required property int index
                        visible: !modelData.hidden
                        width: parent.width; height: 40; radius: 14
                        border.width: win.page === index ? 1 : 0; border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.5)
                        color: win.page === index ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : (ma.containsMouse ? Theme.surfaceContainerHigh : "transparent")
                        Row {
                            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter } spacing: 10
                            Icon { name: modelData.icon; size: 20; color: win.page === index ? Theme.primary : Theme.surfaceFg }
                            Text { text: modelData.name; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter
                                   color: win.page === index ? Theme.primary : Theme.surfaceFg; font.weight: win.page === index ? Font.DemiBold : Font.Normal }
                        }
                        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: win.page = index }
                    }
                }
            }
            }
        }

        // ---- page area
        Loader {
            anchors { left: side.right; right: parent.right; top: parent.top; bottom: bar.top; margins: 28; bottomMargin: 12 }
            source: win.pages[win.page].comp
        }

        // ---- action bar
        Rectangle {
            id: bar
            anchors { left: side.right; right: parent.right; bottom: parent.bottom; leftMargin: 16; rightMargin: 16; bottomMargin: 16 }
            height: 60; radius: 30; color: Theme.surfaceContainer
            border.width: win.confirm ? 2 : 1; border.color: win.confirm ? Theme.primary : Qt.rgba(1, 1, 1, 0.14)

            // status
            Row {
                anchors { left: parent.left; leftMargin: 22; verticalCenter: parent.verticalCenter } spacing: 10
                Rectangle { width: 10; height: 10; radius: 5; anchors.verticalCenter: parent.verticalCenter
                            color: Config.dirty ? Theme.primary : Theme.outline }
                Text { anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 13; color: Theme.surfaceFgDim
                       text: win.confirm ? "Unsaved changes. Save before closing?" : (Config.dirty ? "Unsaved changes (previewing live)" : "All changes saved") }
            }

            // normal buttons
            Row {
                visible: !win.confirm
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } spacing: 8
                PillButton { label: "Reload shell"; icon: "restart_alt"; onClicked: Quickshell.reload(true) }
                PillButton { label: "Discard"; icon: "undo"; enabled: Config.dirty; onClicked: Config.discard() }
                PillButton { label: "Save"; icon: "save"; filled: true; enabled: Config.dirty; onClicked: Config.save() }
            }
            // close prompt
            Row {
                visible: win.confirm
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } spacing: 8
                PillButton { label: "Cancel"; onClicked: win.confirm = false }
                PillButton { label: "Discard & close"; icon: "undo"; onClicked: { Config.discard(); win.confirm = false; UiState.settingsOpen = false } }
                PillButton { label: "Save & close"; icon: "save"; filled: true; onClicked: { Config.save(); win.confirm = false; UiState.settingsOpen = false } }
            }
        }

        IconButton { icon: "close"; diameter: 34; iconSize: 18; anchors { top: parent.top; right: parent.right; margins: 16 }
                     onClicked: win.requestClose() }
    }
}
