// =============================================================================
//  WallpaperSlide — horizontal carousel of the images in wallpaperDir.
//  Scroll (wheel/drag) to browse, click to apply. Colors regenerate
//  automatically via Theme (matugen).
// =============================================================================
import QtQuick
import Qt.labs.folderlistmodel
import qs.config
import qs.services
import qs.components

Item {
    id: s
    height: 200
    width: parent ? parent.width : 600

    FolderListModel {
        id: fm
        folder: "file://" + Config.appearance.wallpaperDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        caseSensitive: false
        showDirs: false
        onStatusChanged: if (status === FolderListModel.Ready) s.syncIndex()
    }

    // center the carousel on the active wallpaper
    function syncIndex() {
        for (let i = 0; i < fm.count; i++)
            if (fm.get(i, "filePath") === Config.appearance.wallpaper) { lv.currentIndex = i; return }
    }

    ListView {
        id: lv
        anchors.fill: parent
        orientation: ListView.Horizontal
        model: fm; spacing: 18; clip: true
        highlightRangeMode: ListView.StrictlyEnforceRange     // keeps current item centered
        preferredHighlightBegin: width / 2 - 130
        preferredHighlightEnd: width / 2 + 130
        highlightMoveDuration: 260
        cacheBuffer: 600

        delegate: Item {
            id: d
            required property string filePath
            required property int index
            readonly property bool cur: ListView.isCurrentItem
            readonly property bool active: filePath === Config.appearance.wallpaper
            width: 260; height: lv.height
            Rectangle {
                anchors.centerIn: parent
                width: 260; height: 160; radius: 18; color: Theme.surfaceContainerHigh
                scale: d.cur ? 1.12 : 0.88; opacity: d.cur ? 1 : 0.6
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200 } }
                border.width: d.active ? 3 : 0; border.color: Theme.primary
                Image {
                    anchors.fill: parent; anchors.margins: d.active ? 3 : 0
                    source: "file://" + d.filePath; asynchronous: true; fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(520, 320)    // thumbnail only: saves memory
                }
                Icon { visible: d.active; name: "check_circle"; size: 26; color: Theme.primary
                       anchors { right: parent.right; top: parent.top; margins: 8 } }
            }
            MouseArea { anchors.fill: parent; onClicked: { lv.currentIndex = d.index; Config.appearance.wallpaper = d.filePath } }
        }

        WheelHandler {
            onWheel: e => { lv.currentIndex = Math.max(0, Math.min(lv.count - 1, lv.currentIndex + (e.angleDelta.y < 0 ? 1 : -1))) }
        }
    }

    Text { visible: fm.count === 0; anchors.centerIn: parent; color: Theme.onSurfaceVariant; font.pixelSize: 13
           text: "No images in " + Config.appearance.wallpaperDir }
}
