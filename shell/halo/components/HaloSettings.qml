import QtQuick
import Quickshell
import Quickshell.Services.UPower
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

    readonly property string pageTitle: UI.settingsSub !== "" ? UI.settingsSubTitle : labelOf(cur)
    readonly property bool backVisible: UI.settingsSub !== "" || (!wide && page !== "")
    readonly property var subs: ({ "kit/demo": cKitSub })

    function goBack() {
        if (UI.settingsSub !== "")
            UI.settingsSub = "";
        else if (!wide && page !== "")
            page = "";
        else
            UI.closeSettings();
    }

    // Second line of the category list (AOSP top-level summaries).
    function summaryOf(key) {
        if (key === "wifi")
            return System.wifi ? (System.wifiName !== "" ? System.wifiName : "On") : "Off";
        if (key === "bluetooth")
            return System.bluetooth ? "On" : "Off";
        if (key === "battery") {
            const d = UPower.displayDevice;
            return d ? Math.round(d.percentage * 100) + "%" + (d.state === UPowerDeviceState.Charging ? ", charging" : "") : "";
        }
        if (key === "storage") {
            const k = Info.disk("root");
            return k.size > 0 ? Info.gb(k.used) + " used of " + Info.gb(k.size) : "";
        }
        if (key === "sound")
            return System.muted ? "Muted" : "Volume " + Math.round(System.volume * 100) + "%";
        if (key === "display")
            return "Brightness " + Math.round(System.brightness * 100) + "%";
        return "";
    }

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
            root.goBack();
        }
    }

    onPageChanged: UI.settingsSub = ""
    Connections {
        target: UI
        function onSettingsSubChanged() {
            content.contentY = 0;
        }
    }

    onShownChanged: {
        if (shown) {
            UI.settingsSub = "";
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
    Component { id: cKitSub; SetPageKitSub {} }

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
                visible: root.backVisible
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
                    onClicked: root.goBack()
                }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: root.backVisible ? 84 : 32
                anchors.verticalCenter: parent.verticalCenter
                text: root.wide ? (UI.settingsSub !== "" || content.contentY > 40 ? root.pageTitle : "Settings") : (root.page === "" ? "Settings" : root.pageTitle)
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
                        Column {
                            x: 68
                            width: parent.width - 68 - (root.wide ? 12 : 44)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                width: parent.width
                                text: cat.modelData.label
                                color: Theme.text
                                font.pixelSize: 18
                                elide: Text.ElideRight
                            }
                            Text {
                                visible: text !== ""
                                width: parent.width
                                text: root.summaryOf(cat.modelData.key)
                                color: Theme.dim
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
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
                text: root.pageTitle
                color: Theme.text
                font.pixelSize: 26
                font.weight: Font.DemiBold
            }

            Loader {
                id: loader
                y: root.wide ? 56 : 8
                width: content.width
                sourceComponent: (UI.settingsSub !== "" ? root.subs[root.cur + "/" + UI.settingsSub] : null) || root.comps[root.cur] || null
            }
        }
    }
}
