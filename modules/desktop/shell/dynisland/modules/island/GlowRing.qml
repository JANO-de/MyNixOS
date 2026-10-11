// =============================================================================
//  GlowRing — glowing line around the island (cava style "glow").
//  Instantiate as a child of the pill with z:-1 so it paints behind it.
//  Brightness/thickness follow Cava.level. Config.cava.rainbow cycles hue.
// =============================================================================
import QtQuick
import QtQuick.Effects
import qs.config
import qs.services

Item {
    id: g
    anchors.fill: parent
    visible: Config.cava.style === "glow"

    readonly property real pad: 40
    readonly property real lv: Math.min(1, Cava.level * Config.cava.sensitivity)
    property real hue: 0
    readonly property color tint: Config.cava.rainbow ? Qt.hsla(hue, 0.85, 0.65, 1) : Theme.primary
    NumberAnimation on hue { running: g.visible && Config.cava.rainbow; from: 0; to: 1; duration: 5000; loops: Animation.Infinite }

    // Soft blurred halo (GPU blur of a thick ring)
    Item {
        anchors.fill: parent; anchors.margins: -g.pad
        opacity: Math.min(1, (0.25 + g.lv * 0.9) * Config.cava.glowStrength)
        layer.enabled: g.visible
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 36 }
        Rectangle {
            anchors.fill: parent; anchors.margins: g.pad - 2
            radius: g.parent.radius + 2; color: "transparent"
            border.width: 4 + g.lv * 10; border.color: g.tint
        }
    }
    // Crisp thin line right on the edge
    Rectangle {
        anchors.fill: parent; anchors.margins: -2
        radius: g.parent.radius + 2; color: "transparent"
        border.width: 2; border.color: g.tint; opacity: 0.45 + g.lv * 0.55
    }
}
