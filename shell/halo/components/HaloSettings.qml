import QtQuick
import Quickshell
import qs.services

// Settings app (Android-style). Wide screens: category list on the left, page on the right.
// Narrow screens: the list first, then the page with a back arrow.
// A real Wayland window (title "Settings" -> app id halo-settings), so split, dock dots and Overview treat it like any app.
// Open with: halo-ctl call settings open | the gear in the shade | long-press menu on the home screen.
FloatingWindow {
    id: root

    readonly property bool shown: UI.settingsOpen
    readonly property bool wide: card.width >= 900
    property string page: "" // "" = category list (narrow) / first category (wide)
    readonly property string cur: wide ? (page === "" ? "wifi" : page) : page

    // Order follows AOSP top_level_settings.xml (see docs/B1-aosp-settings.md).
    readonly property var cats: [
        { key: "wifi", glyph: "≋", label: "Network & internet" },
        { key: "bluetooth", glyph: "✧", label: "Connected devices" },
        { key: "apps", glyph: "▦", label: "Apps" },
        { key: "notifs", glyph: "◔", label: "Notifications" },
        { key: "battery", glyph: "▮", label: "Battery" },
        { key: "storage", glyph: "▤", label: "Storage" },
        { key: "sound", glyph: "♪", label: "Sound" },
        { key: "display", glyph: "☀", label: "Display" },
        { key: "home", glyph: "⌂", label: "Home screen" },
        { key: "security", glyph: "⚑", label: "Security & privacy" },
        { key: "updates", glyph: "⟳", label: "Updates" },
        { key: "about", glyph: "ⓘ", label: "About" },
        { key: "kit", glyph: "✦", label: "Component kit (dev)" }
    ]

    readonly property var comps: ({
        wifi: cWifi, bluetooth: cBluetooth, display: cDisplay, sound: cSound, notifs: cNotifs,
        home: cHome, security: cSecurity, apps: cApps, battery: cBattery, storage: cStorage,
        updates: cUpdates, about: cAbout, kit: cKit
    })

    function labelOf(key) {
        for (const c of cats)
            if (c.key === key)
                return c.label;
        return "Settings";
    }

    Connections {
        target: UI
        function onSettingsBackTickChanged() {
            if (!root.shown)
                return;
            if (!root.wide && root.page !== "")
                root.page = "";
            else
                UI.closeSettings();
        }
    }

    onShownChanged: {
        if (shown) {
            page = UI.settingsPage;
            UI.settingsPage = "";
            Info.refresh();
        } else if (Mode.tablet && Kbd.visible) {
            Kbd.hideQuiet();
        }
    }

    title: "Settings"
    implicitWidth: 1100
    implicitHeight: 720
    color: Qt.rgba(Theme.scrim.r, Theme.scrim.g, Theme.scrim.b, 1)
    visible: shown
    // Closed from the compositor (kill / close button): keep UI state in sync.
    onVisibleChanged: {
        if (!visible && UI.settingsOpen)
            UI.closeSettings();
    }

    Component { id: cWifi; SetPageWifi {} }
    Component { id: cBluetooth; SetPageBluetooth {} }
    Component { id: cDisplay; SetPageDisplay {} }
    Component { id: cSound; SetPageSound {} }
    Component { id: cNotifs; SetPageNotifs {} }
    Component { id: cHome; SetPageHome {} }
    Component { id: cSecurity; SetPageSecurity {} }
    Component { id: cApps; SetPageApps {} }
    Component { id: cBattery; SetPageBattery {} }
    Component { id: cStorage; SetPageStorage {} }
    Component { id: cUpdates; SetPageUpdates {} }
    Component { id: cAbout; SetPageAbout {} }
    Component { id: cKit; SetPageKit {} }

    Rectangle {
        id: card
        anchors.fill: parent
        color: "transparent"

        // Swallow touches so nothing behind the settings reacts.
        MouseArea { anchors.fill: parent }

        // Tap anywhere that is not a text field: drop focus, tuck the keyboard away. Checked shortly after
        // release and skipped when a SetInput was pressed or took focus meanwhile (e.g. opening a password row).
        PointHandler {
            id: outside
            property real pressAt: 0
            onActiveChanged: {
                if (active) {
                    pressAt = Date.now();
                    return;
                }
                const d = Math.hypot(point.position.x - point.pressPosition.x, point.position.y - point.pressPosition.y);
                if (d < 24)
                    outsideTimer.restart();
            }
        }
        Timer {
            id: outsideTimer
            interval: 120
            onTriggered: {
                if (UI.inputTapAt >= outside.pressAt - 50 || UI.inputFocusAt >= outside.pressAt - 50)
                    return;
                card.forceActiveFocus();
                if (Mode.tablet && Kbd.visible)
                    Kbd.hideQuiet();
            }
        }

        // ---- Header ------------------------------------------------------------------------
        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 84

            Rectangle {
                visible: !root.wide && root.page !== ""
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 44
                radius: 22
                color: Theme.tint(0.14)

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: Theme.text
                    font.pixelSize: 30
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: root.page = ""
                }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: (!root.wide && root.page !== "") ? 84 : 32
                anchors.verticalCenter: parent.verticalCenter
                text: root.wide ? (content.contentY > 40 ? root.labelOf(root.cur) : "Settings") : (root.page === "" ? "Settings" : root.labelOf(root.page))
                color: Theme.text
                font.pixelSize: 30
                font.weight: Font.DemiBold
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 44
                radius: 22
                color: Theme.tint(0.14)

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: Theme.text
                    font.pixelSize: 18
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: UI.closeSettings()
                }
            }
        }

        // ---- Category list -------------------------------------------------------------------
        Flickable {
            id: side
            visible: root.wide || root.page === ""
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: 20
            width: root.wide ? 320 : parent.width - 40
            clip: true
            contentWidth: width
            contentHeight: catCol.height + 24
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: catCol
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.cats

                    Rectangle {
                        id: cat
                        required property var modelData
                        readonly property bool selected: root.wide && root.cur === modelData.key

                        width: catCol.width
                        height: 64
                        radius: 22
                        color: selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.26) : (catTap.pressed ? Theme.surfacePress : "transparent")
                        Behavior on color { ColorAnimation { duration: 90 } }

                        Rectangle {
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 40
                            height: 40
                            radius: 20
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)

                            Text {
                                anchors.centerIn: parent
                                text: cat.modelData.glyph
                                color: Theme.accent
                                font.pixelSize: 20
                            }
                        }
                        Text {
                            x: 68
                            anchors.verticalCenter: parent.verticalCenter
                            text: cat.modelData.label
                            color: Theme.text
                            font.pixelSize: 18
                        }
                        Text {
                            visible: !root.wide
                            anchors.right: parent.right
                            anchors.rightMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"
                            color: Theme.dim
                            font.pixelSize: 26
                        }
                        MouseArea {
                            id: catTap
                            anchors.fill: parent
                            onClicked: root.page = cat.modelData.key
                        }
                    }
                }
            }
        }

        // ---- Page ----------------------------------------------------------------------------
        Flickable {
            id: content
            visible: root.wide || root.page !== ""
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.left: root.wide ? side.right : parent.left
            anchors.leftMargin: root.wide ? 28 : 20
            clip: true
            contentWidth: width
            contentHeight: (loader.item ? loader.item.height : 0) + (root.wide ? 80 : 20) + 40
            boundsBehavior: Flickable.StopAtBounds

            // Heading above the page (wide layout; the header already names the page when narrow).
            Text {
                visible: root.wide
                opacity: Math.max(0, 1 - content.contentY / 40)
                y: 4
                text: root.labelOf(root.cur)
                color: Theme.text
                font.pixelSize: 26
                font.weight: Font.DemiBold
            }

            Loader {
                id: loader
                y: root.wide ? 56 : 8
                width: content.width
                sourceComponent: root.comps[root.cur] || null
            }
        }
    }
}
