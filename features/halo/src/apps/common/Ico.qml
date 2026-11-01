import QtQuick
import QtQuick.Shapes
import qs.common

// Line icon by name (see Ic.qml), tinted with `color`.
Item {
    id: r
    property string name: ""
    property color color: AppTheme.text
    property real size: 24
    property bool filled: false
    width: size
    height: size
    Shape {
        width: 48
        height: 48
        scale: r.size / 48
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: r.color
            strokeWidth: 2.6
            fillColor: r.filled ? r.color : "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: Ic.p[r.name] || "" }
        }
    }
}
