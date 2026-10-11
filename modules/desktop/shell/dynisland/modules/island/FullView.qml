// Expanded island: three columns (media | clock+weather | controls).
// Fixed size so the layout doesn't reflow while the pill is still animating.
import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: v
    property bool active: false
    anchors.centerIn: parent
    width: Config.island.fullWidth - 40
    height: Config.island.fullHeight - 40
    opacity: active ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 180 } }

    RowLayout {
        anchors.fill: parent; spacing: 16
        MediaCard { active: v.active; Layout.preferredWidth: 210; Layout.fillHeight: true }
        // middle column takes what is left; it must never push the others out (min 0, preferred 0)
        ClockCard { Layout.fillWidth: true; Layout.preferredWidth: 0; Layout.minimumWidth: 0; Layout.fillHeight: true }
        ControlsCard { Layout.preferredWidth: 190; Layout.minimumWidth: 190; Layout.maximumWidth: 190; Layout.fillHeight: true }
    }
}
