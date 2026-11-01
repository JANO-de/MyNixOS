// Round icon button. `active` paints it with the theme accent; `flat` drops the background.
import QtQuick
import QtQuick.Controls.Basic
import qs.services

Rectangle {
    id: b
    property string icon: ""
    property bool active: false
    property bool flat: false
    property int iconSize: 20
    property int diameter: 40
    property string tip: ""
    signal clicked()
    ToolTip.visible: tip !== "" && ma.containsMouse
    ToolTip.text: tip
    ToolTip.delay: 400

    implicitWidth: diameter; implicitHeight: diameter; radius: diameter / 2
    color: active ? Theme.primary : (ma.containsMouse ? "#2effffff" : (flat ? "transparent" : "#16ffffff"))
    border.width: flat && !active ? 0 : 1
    border.color: active ? Qt.lighter(Theme.primary, 1.25) : "#1fffffff"
    scale: ma.pressed ? 0.9 : (ma.containsMouse ? 1.06 : 1)
    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack; easing.overshoot: 2 } }

    Icon { anchors.centerIn: parent; name: b.icon; size: b.iconSize; color: b.active ? Theme.primaryFg : (b.flat && !ma.containsMouse ? "#ddffffff" : "white") }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: b.clicked() }
}
