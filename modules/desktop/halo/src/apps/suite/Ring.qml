import QtQuick
import QtQuick.Shapes
import qs.common

// Circular progress ring (timer). value 0..1; children go in the middle.
Item {
    id: r
    property real value: 1
    property real thickness: 14
    property color trackColor: AppTheme.cardHigh
    property color barColor: AppTheme.accent
    default property alias content: inner.data
    readonly property real rad: (Math.min(width, height) - thickness) / 2

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: r.trackColor
            strokeWidth: r.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: r.width / 2
                centerY: r.height / 2
                radiusX: r.rad
                radiusY: r.rad
                startAngle: -90
                sweepAngle: 359.9
            }
        }
        ShapePath {
            strokeColor: r.barColor
            strokeWidth: r.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: r.width / 2
                centerY: r.height / 2
                radiusX: r.rad
                radiusY: r.rad
                startAngle: -90
                sweepAngle: Math.max(0.5, Math.min(1, r.value)) * 359.9
            }
        }
    }
    Item {
        id: inner
        anchors.fill: parent
    }
}
