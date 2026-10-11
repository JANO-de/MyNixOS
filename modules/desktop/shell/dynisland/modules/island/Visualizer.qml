// =============================================================================
//  Visualizer — in-pill cava styles drawn behind the content:
//    "bars"  equalizer bars rising from the bottom edge
//    "wave"  mirrored waveform line through the middle
//    "mirror" bars growing up and down from the centre line
//    "dots"  a row of dots that swell with each band
//  ("glow" is GlowRing.qml, "pulse" scales the pill in Island.qml.)
//  TO ADD A STYLE: add an Item below with visible: Config.cava.style === "name"
//  and list the name in modules/settings/VisualizerPage.qml.
// =============================================================================
import QtQuick
import QtQuick.Shapes
import qs.config
import qs.services

Item {
    id: v
    anchors.fill: parent
    property real hue: 0
    NumberAnimation on hue { running: Config.cava.rainbow && Config.cava.style !== "glow" && Config.cava.style !== "none"; from: 0; to: 1; duration: 5000; loops: Animation.Infinite }
    readonly property color tint: Config.cava.rainbow ? Qt.hsla(hue, 0.85, 0.65, 1) : Theme.primary
    readonly property real pad: Math.max(16, parent.radius * 0.7)
    readonly property real sens: Config.cava.sensitivity

    // ---- bars
    Item {
        visible: Config.cava.style === "bars"
        anchors { fill: parent; leftMargin: v.pad; rightMargin: v.pad }
        readonly property real gap: 3
        readonly property real bw: (width - (Cava.barCount - 1) * gap) / Cava.barCount
        Repeater {
            model: Cava.barCount
            Rectangle {
                x: index * (parent.bw + parent.gap); width: parent.bw; radius: width / 2
                anchors.bottom: parent.bottom
                height: Math.max(2, Math.min(1, (Cava.values[index] || 0) * v.sens) * parent.height * 0.85)
                color: v.tint; opacity: 0.4
            }
        }
    }

    // ---- wave
    Shape {
        id: wave
        visible: Config.cava.style === "wave"
        anchors.fill: parent
        layer.enabled: visible; layer.samples: 4
        function pts(sign) {
            const n = Cava.barCount, w = width - 2 * v.pad, out = [];
            for (let i = 0; i < n; i++)
                out.push(Qt.point(v.pad + w * i / (n - 1),
                                  height / 2 + sign * Math.min(1, (Cava.values[i] || 0) * v.sens) * height * 0.38));
            return out;
        }
        ShapePath { strokeColor: v.tint; strokeWidth: 2; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    PathPolyline { path: wave.pts(-1) } }
        ShapePath { strokeColor: v.tint; strokeWidth: 2; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                    PathPolyline { path: wave.pts(1) } }
    }

    // ---- mirror: bars symmetric around the middle
    Item {
        visible: Config.cava.style === "mirror"
        anchors { fill: parent; leftMargin: v.pad; rightMargin: v.pad }
        readonly property real gap: 3
        readonly property real bw: (width - (Cava.barCount - 1) * gap) / Cava.barCount
        Repeater {
            model: Cava.barCount
            Rectangle {
                x: index * (parent.bw + parent.gap); width: parent.bw; radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                height: Math.max(2, Math.min(1, (Cava.values[index] || 0) * v.sens) * parent.height * 0.8)
                color: v.tint; opacity: 0.4
            }
        }
    }

    // ---- dots: circle diameter follows each band
    Item {
        visible: Config.cava.style === "dots"
        anchors { fill: parent; leftMargin: v.pad; rightMargin: v.pad }
        readonly property real slot: width / Cava.barCount
        Repeater {
            model: Cava.barCount
            Rectangle {
                readonly property real d: 3 + Math.min(1, (Cava.values[index] || 0) * v.sens) * 9
                width: d; height: d; radius: d / 2
                x: index * parent.slot + (parent.slot - d) / 2
                anchors.verticalCenter: parent.verticalCenter
                color: v.tint; opacity: 0.55
            }
        }
    }
}
