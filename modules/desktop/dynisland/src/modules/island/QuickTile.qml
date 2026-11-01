// Control-center style tile (icon + label) used on the island's second page (QuickPage.qml).
import QtQuick
import QtQuick.Controls.Basic
import qs.services
import qs.components

Rectangle {
    id: t
    property string icon: ""
    property string label: ""
    property bool active: false
    property string tip: ""
    signal clicked()
    implicitWidth: 46; implicitHeight: 46; radius: 16
    color: active ? Theme.primary : (ma.containsMouse ? "#2effffff" : "#16ffffff")
    border.width: 1; border.color: active ? Qt.lighter(Theme.primary, 1.25) : "#1fffffff"
    scale: ma.pressed ? 0.93 : (ma.containsMouse ? 1.04 : 1)
    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack; easing.overshoot: 2 } }
    ToolTip.visible: tip !== "" && ma.containsMouse
    ToolTip.text: tip
    ToolTip.delay: 400
    Column {
        anchors.centerIn: parent; spacing: 1
        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: t.icon; size: 18; color: t.active ? Theme.primaryFg : "white" }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: t.label; font.pixelSize: 9; font.weight: Font.Medium
               color: t.active ? Theme.primaryFg : "#bbffffff" }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: t.clicked() }
}
