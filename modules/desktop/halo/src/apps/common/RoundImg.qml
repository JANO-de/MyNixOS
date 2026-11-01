import QtQuick
import QtQuick.Effects

// Image with rounded corners (mask), cropped to fill.
Item {
    id: r
    property alias source: img.source
    property real radius: 16
    property int px: 200
    readonly property bool ready: img.status === Image.Ready
    Image {
        id: img
        anchors.fill: parent
        visible: false
        sourceSize: Qt.size(r.px, r.px)
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
    }
    Rectangle {
        id: m
        anchors.fill: parent
        radius: r.radius
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        source: img
        maskEnabled: true
        maskSource: m
        visible: r.ready
    }
}
