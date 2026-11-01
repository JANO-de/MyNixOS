// Desktop widget layer (above wallpaper, below windows). Input masked to the cards.
// Widgets: clock, weather, media, system (CPU/RAM/disk), calendar.
// TO ADD ONE: copy a DesktopWidget block, give it a unique wid, add it to `mask`,
// add a toggle in Config.widgets and Settings > Widgets.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

PanelWindow {
    id: win
    visible: !(Sys.focusMode && Config.system.focusHide)   // Focus mode hides it
    required property var modelData
    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "dynisland-widgets"
    mask: Region { Region { item: clockW } Region { item: weatherW } Region { item: mediaW } Region { item: sysW } Region { item: calW } Region { item: recentW } Region { item: shelfW } }

    // Poll CPU/RAM only while the system widget is shown
    Binding { target: Stats; property: "watching"; value: Config.widgets.system }
    Binding { target: Recent; property: "watching"; value: Config.widgets.recent }

    function fileIcon(n) {
        const e = n.substring(n.lastIndexOf(".") + 1).toLowerCase();
        if (["png", "jpg", "jpeg", "webp", "gif", "svg"].indexOf(e) >= 0) return "image";
        if (["mp4", "mkv", "webm", "mov"].indexOf(e) >= 0) return "movie";
        if (["mp3", "flac", "ogg", "wav", "m4a"].indexOf(e) >= 0) return "music_note";
        if (e === "pdf") return "picture_as_pdf";
        if (["zip", "tar", "xz", "gz", "7z", "rar"].indexOf(e) >= 0) return "folder_zip";
        return "description";
    }

    // Reusable labelled usage bar (QML inline component: define once, instantiate many times)
    component StatBar: Item {
        property string label: ""
        property real value: 0
        property string valueText: ""
        width: 210; height: 34
        Text { anchors.left: parent.left; text: parent.label; color: "#ccffffff"; font.pixelSize: 12; font.weight: Font.Medium }
        Text { anchors.right: parent.right; text: parent.valueText; color: "white"; font.pixelSize: 12 }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 6; radius: 3; color: "#33ffffff"
            Rectangle {
                height: parent.height; radius: 3; color: Theme.primary
                width: parent.width * Math.max(0, Math.min(1, parent.parent.value))
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }
    }

    // ---- Clock
    DesktopWidget {
        id: clockW; wid: "clock"; panel: "clock"; defX: 80; defY: 100
        visible: Config.widgets.clock; width: visible ? implicitWidth : 0; height: visible ? implicitHeight : 0
        Column {
            spacing: 2
            Text { text: Clock.time; color: "white"; font.pixelSize: 64; font.weight: Font.Bold }
            Text { text: Clock.dateLong; color: "#ccffffff"; font.pixelSize: 16 }
        }
    }

    // ---- Weather
    DesktopWidget {
        id: weatherW; wid: "weather"; panel: "weather"; defX: 80; defY: 280
        visible: Config.widgets.weather; width: visible ? implicitWidth : 0; height: visible ? implicitHeight : 0
        Row {
            spacing: 14
            Icon { name: Weather.icon; size: 46; color: Theme.primary }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text { text: Weather.temp; color: "white"; font.pixelSize: 30; font.weight: Font.DemiBold }
                Text { text: Weather.cond; color: "#ccffffff"; font.pixelSize: 13 }
            }
        }
    }

    // ---- Media
    DesktopWidget {
        id: mediaW; wid: "media"; defX: 80; defY: 400
        visible: Config.widgets.media; width: visible ? implicitWidth : 0; height: visible ? implicitHeight : 0
        Row {
            spacing: 14
            ClippingRectangle {
                width: 64; height: 64; radius: 16; color: "#222"
                Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 128 }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter; width: 170; spacing: 2
                Text { width: parent.width; elide: Text.ElideRight; text: Media.player ? Media.title : "Nothing playing"
                       color: "white"; font.pixelSize: 15; font.weight: Font.DemiBold }
                Text { width: parent.width; elide: Text.ElideRight; text: Media.artist; color: "#aaffffff"; font.pixelSize: 12 }
            }
        }
    }

    // ---- System monitor
    DesktopWidget {
        id: sysW; wid: "system"; defX: 80; defY: 540
        visible: Config.widgets.system; width: visible ? implicitWidth : 0; height: visible ? implicitHeight : 0
        Column {
            spacing: 8
            StatBar { label: "CPU";  value: Stats.cpu;  valueText: Math.round(Stats.cpu * 100) + "%" }
            StatBar { label: "RAM";  value: Stats.ram;  valueText: Stats.ramText }
            StatBar { label: "Disk"; value: Stats.disk; valueText: Math.round(Stats.disk * 100) + "%" }
        }
    }

    // ---- Calendar (Monday-first month grid; today highlighted)
    DesktopWidget {
        id: calW; wid: "calendar"; panel: "calendar"; defX: 380; defY: 100
        visible: Config.widgets.calendar; width: visible ? implicitWidth : 0; height: visible ? implicitHeight : 0

        QtObject {
            id: cal
            property var today: new Date()
            // weekday of the 1st, shifted so Monday = 0
            readonly property int offset: (new Date(today.getFullYear(), today.getMonth(), 1).getDay() + 6) % 7
            readonly property int dim: new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()
        }
        Timer { interval: 60000; repeat: true; running: calW.visible; onTriggered: cal.today = new Date() }

        Column {
            spacing: 8
            Text { text: Qt.formatDate(cal.today, "MMMM yyyy"); color: "white"; font.pixelSize: 16; font.weight: Font.DemiBold }
            Grid {
                columns: 7; spacing: 4
                Repeater {
                    model: ["M", "T", "W", "T", "F", "S", "S"]
                    Text { required property string modelData
                           width: 28; height: 18; horizontalAlignment: Text.AlignHCenter
                           text: modelData; color: "#99ffffff"; font.pixelSize: 11 }
                }
                Repeater {
                    model: 42
                    Rectangle {
                        required property int index
                        readonly property int day: index - cal.offset + 1
                        readonly property bool valid: day >= 1 && day <= cal.dim
                        readonly property bool isToday: valid && day === cal.today.getDate()
                        width: 28; height: 28; radius: 14
                        color: isToday ? Theme.primary : "transparent"
                        Text { anchors.centerIn: parent; visible: parent.valid; text: parent.day; font.pixelSize: 12
                               color: parent.isToday ? Theme.primaryFg : "#ddffffff" }
                        Rectangle {   // event dot (Settings > Calendar)
                            visible: parent.valid && Agenda.hasEvents(new Date(cal.today.getFullYear(), cal.today.getMonth(), parent.day))
                            width: 4; height: 4; radius: 2; color: parent.isToday ? Theme.primaryFg : Theme.primary
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 1 }
                        }
                    }
                }
            }
        }
    }

    // ---- Recent files (click = open, from recently-used.xbel)
    DesktopWidget {
        id: recentW; wid: "recent"; defX: 380; defY: 400
        visible: Config.widgets.recent; width: visible ? implicitWidth : 0; height: visible ? implicitHeight : 0
        Column {
            spacing: 4
            Text { text: "Recent files"; color: "white"; font.pixelSize: 16; font.weight: Font.DemiBold; bottomPadding: 4 }
            Text { visible: Recent.items.length === 0; text: "Nothing yet"; color: "#99ffffff"; font.pixelSize: 12 }
            Repeater {
                model: Recent.items.slice(0, 6)
                Rectangle {
                    required property var modelData
                    width: 230; height: 28; radius: 10; color: rh.hovered ? "#22ffffff" : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Row {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 6 } spacing: 8
                        Icon { name: win.fileIcon(modelData.name); size: 16; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                        Text { width: 190; elide: Text.ElideMiddle; text: modelData.name; color: "#eeffffff"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    }
                    HoverHandler { id: rh }
                    TapHandler { onTapped: Quickshell.execDetached(["xdg-open", modelData.path]) }
                }
            }
        }
    }

    // ---- File shelf: drop files here, click to open, drag out to copy, right-click to remove
    DesktopWidget {
        id: shelfW; wid: "shelf"; defX: 680; defY: 100
        visible: Config.widgets.fileShelf; width: visible ? implicitWidth : 0; height: visible ? implicitHeight : 0
        function add(urls) {
            const cur = Config.widgets.shelfItems.slice();
            for (const u of urls) {
                let p = u.toString().replace(/^file:\/\//, "");
                try { p = decodeURIComponent(p) } catch (e) {}
                if (cur.indexOf(p) < 0) cur.push(p);
            }
            Config.widgets.shelfItems = cur;
        }
        function remove(p) { Config.widgets.shelfItems = Config.widgets.shelfItems.filter(x => x !== p) }
        Column {
            spacing: 4
            Row {
                spacing: 8
                Text { text: "Shelf"; color: "white"; font.pixelSize: 16; font.weight: Font.DemiBold; bottomPadding: 4 }
                Text { visible: Config.widgets.shelfItems.length > 0; text: "clear"; color: "#99ffffff"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter
                       TapHandler { onTapped: Config.widgets.shelfItems = [] } }
            }
            Rectangle {
                visible: Config.widgets.shelfItems.length === 0
                width: 230; height: 54; radius: 14; color: shelfDrop.containsDrag ? "#22ffffff" : "transparent"
                border.width: 1; border.color: "#44ffffff"
                Text { anchors.centerIn: parent; text: "Drop files here"; color: "#99ffffff"; font.pixelSize: 12 }
            }
            Repeater {
                model: Config.widgets.shelfItems
                Rectangle {
                    id: row
                    required property string modelData
                    readonly property string nm: modelData.substring(modelData.lastIndexOf("/") + 1)
                    width: 230; height: 28; radius: 10; color: sh.hovered ? "#22ffffff" : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Drag.active: dg.active; Drag.dragType: Drag.Automatic; Drag.supportedActions: Qt.CopyAction
                    Drag.mimeData: ({ "text/uri-list": "file://" + modelData })
                    Row {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 6 } spacing: 8
                        Icon { name: win.fileIcon(row.nm); size: 16; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                        Text { width: 190; elide: Text.ElideMiddle; text: row.nm; color: "#eeffffff"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    }
                    HoverHandler { id: sh }
                    DragHandler { id: dg; target: null }
                    TapHandler { onTapped: Quickshell.execDetached(["xdg-open", row.modelData]) }
                    TapHandler { acceptedButtons: Qt.RightButton; onTapped: shelfW.remove(row.modelData) }
                }
            }
        }
        DropArea {
            id: shelfDrop; parent: shelfW; anchors.fill: shelfW; z: -1
            onDropped: drop => { if (drop.hasUrls) shelfW.add(drop.urls); drop.accept() }
        }
    }
}
