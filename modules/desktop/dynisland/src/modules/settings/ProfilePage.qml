// =============================================================================
//  ProfilePage — name, description, avatar and banner. Opened by clicking the
//  profile row at the top of the Settings sidebar. Images are picked from
//  Config.profile.imageDir (default ~/Pictures/Profile). Stored in Config.profile.
// =============================================================================
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services
import qs.components

Page {
    id: pg
    title: "Profile"

    FolderListModel {
        id: imgs
        folder: "file://" + Config.profile.imageDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.svg"]
        caseSensitive: false; showDirs: false
    }

    // ---- live preview: banner + avatar + name
    ClippingRectangle {
        width: parent.width; height: 170; radius: 24; color: Theme.surfaceContainer
        Image {
            anchors.fill: parent; visible: Config.profile.banner !== ""; asynchronous: true
            source: Config.profile.banner !== "" ? "file://" + Config.profile.banner : ""
            fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(900, 300)
        }
        Rectangle {   // soft scrim so the text stays readable on any banner
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 90; gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: "#99000000" }
            }
        }
        ClippingRectangle {
            id: pAv; width: 84; height: 84; radius: 42; color: Theme.primary
            anchors { left: parent.left; leftMargin: 24; bottom: parent.bottom; bottomMargin: 20 }
            Image { anchors.fill: parent; visible: Config.profile.avatar !== ""; asynchronous: true
                    source: Config.profile.avatar !== "" ? "file://" + Config.profile.avatar : ""
                    fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(200, 200) }
            Icon { visible: Config.profile.avatar === ""; anchors.centerIn: parent; name: "person"; size: 44; color: Theme.primaryFg }
        }
        Column {
            anchors { left: pAv.right; leftMargin: 18; right: parent.right; rightMargin: 24; verticalCenter: pAv.verticalCenter }
            Text { width: parent.width; elide: Text.ElideRight; color: "white"; font.pixelSize: 24; font.weight: Font.Bold
                   text: Config.profile.name !== "" ? Config.profile.name : Quickshell.env("USER") }
            Text { width: parent.width; elide: Text.ElideRight; color: "#ddffffff"; font.pixelSize: 14
                   visible: text !== ""; text: Config.profile.description }
        }
    }
    Item { width: 1; height: 12 }

    SettingRow { label: "Name"; hint: "Empty = login name"
        Field { implicitWidth: 280; text: Config.profile.name; placeholder: Quickshell.env("USER")
                onAccepted: t => { if (t !== Config.profile.name) Config.profile.name = t } } }
    SettingRow { label: "Description"
        Field { implicitWidth: 280; text: Config.profile.description; placeholder: "A short line under your name"
                onAccepted: t => { if (t !== Config.profile.description) Config.profile.description = t } } }
    SettingRow { label: "Image folder"; hint: "Avatar and banner are picked from here"
        Field { implicitWidth: 280; text: Config.profile.imageDir
                onAccepted: t => { if (t !== "" && t !== Config.profile.imageDir) Config.profile.imageDir = t } } }

    Text { visible: imgs.count === 0; width: parent.width; wrapMode: Text.WordWrap; topPadding: 8; bottomPadding: 8
           color: Theme.surfaceFgDim; font.pixelSize: 13
           text: "No images in " + Config.profile.imageDir + ". Put pictures there (jpg, png, webp, svg) or change the folder." }

    // ---- avatar picker
    SettingRow { label: "Avatar"; implicitHeight: 48
        PillButton { label: "Clear"; icon: "close"; enabled: Config.profile.avatar !== ""; onClicked: Config.profile.avatar = "" } }
    Flow {
        width: parent.width; spacing: 10
        Repeater {
            model: imgs
            delegate: Item {
                id: ad
                required property string filePath
                readonly property bool active: filePath === Config.profile.avatar
                width: 68; height: 68
                ClippingRectangle {
                    anchors.fill: parent; radius: 34; color: Theme.surfaceContainerHigh
                    border.width: ad.active ? 3 : 0; border.color: Theme.primary
                    Image { anchors.fill: parent; asynchronous: true; source: "file://" + ad.filePath
                            fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(160, 160) }
                }
                MouseArea { anchors.fill: parent; onClicked: Config.profile.avatar = ad.filePath }
            }
        }
    }
    Item { width: 1; height: 12 }

    // ---- banner picker
    SettingRow { label: "Banner"; implicitHeight: 48
        PillButton { label: "Clear"; icon: "close"; enabled: Config.profile.banner !== ""; onClicked: Config.profile.banner = "" } }
    Flow {
        width: parent.width; spacing: 10
        Repeater {
            model: imgs
            delegate: Item {
                id: bd
                required property string filePath
                readonly property bool active: filePath === Config.profile.banner
                width: 140; height: 64
                ClippingRectangle {
                    anchors.fill: parent; radius: 14; color: Theme.surfaceContainerHigh
                    border.width: bd.active ? 3 : 0; border.color: Theme.primary
                    Image { anchors.fill: parent; asynchronous: true; source: "file://" + bd.filePath
                            fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(280, 128) }
                }
                MouseArea { anchors.fill: parent; onClicked: Config.profile.banner = bd.filePath }
            }
        }
    }
}
