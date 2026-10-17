// Expanded island: three columns (media | clock+weather | controls).
// Fixed size so the layout doesn't reflow while the pill is still animating.
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

Item {
    id: v
    property bool active: false
    anchors.centerIn: parent
    width: Config.island.fullWidth - 40
    height: Config.island.fullHeight - 40
    opacity: active ? 1 : 0
    visible: opacity > 0.01
    scale: active ? 1 : 0.95   // content settles in as the pill morphs
    Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    RowLayout {
        anchors.fill: parent; spacing: 12
        MediaCard { active: v.active; Layout.preferredWidth: 210; Layout.fillHeight: true }
        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; Layout.topMargin: 10; Layout.bottomMargin: 10; color: "#1affffff" }
        // middle column takes what is left; it must never push the others out (min 0, preferred 0)
        ClockCard { Layout.fillWidth: true; Layout.preferredWidth: 0; Layout.minimumWidth: 0; Layout.fillHeight: true }
        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; Layout.topMargin: 10; Layout.bottomMargin: 10; color: "#1affffff" }
        Item {   // right column: page 1 = controls, page 2 = quick toggles (slides)
            Layout.preferredWidth: 190; Layout.minimumWidth: 190; Layout.maximumWidth: 190; Layout.fillHeight: true
            clip: true
            ControlsCard {
                width: parent.width; height: parent.height
                x: UiState.quickPage ? -width - 20 : 0; opacity: UiState.quickPage ? 0 : 1; visible: !UiState.quickPage
                Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            }
            QuickPage {
                width: parent.width; anchors.verticalCenter: parent.verticalCenter
                x: UiState.quickPage ? 0 : parent.width + 20; opacity: UiState.quickPage ? 1 : 0; visible: UiState.quickPage
                Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            }
        }
    }
}
