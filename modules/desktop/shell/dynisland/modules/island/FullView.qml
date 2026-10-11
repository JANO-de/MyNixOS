// Expanded island: three columns (media | clock+weather | controls).
// Fixed size so the layout doesn't reflow while the pill is still animating.
import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: v
    property bool active: false
    anchors.centerIn: parent
    width: Config.island.fullWidth - 48
    height: Config.island.fullHeight - 40
    opacity: active ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 180 } }

    RowLayout {
        anchors.fill: parent; spacing: 22
        MediaCard { active: v.active; Layout.preferredWidth: 220; Layout.fillHeight: true }
        ClockCard { Layout.fillWidth: true; Layout.fillHeight: true }
        ControlsCard { Layout.preferredWidth: 190; Layout.fillHeight: true }
    }
}
