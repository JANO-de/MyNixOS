import QtQuick
import QtQuick.Effects
import qs.services

// Photo frame: shows the photos picked with the pencil (edit mode); cycles every 30 s, tap = next.
Item {
    id: root
    property var inst: null
    readonly property var photos: inst && inst.cfg && inst.cfg.photos ? inst.cfg.photos : []
    property int idx: 0
    readonly property string src: photos.length > 0 ? "file://" + photos[idx % photos.length] : ""

    Timer {
        interval: 30000
        repeat: true
        running: root.photos.length > 1
        onTriggered: root.idx = (root.idx + 1) % root.photos.length
    }

    Image {
        id: img
        anchors.fill: parent
        visible: false
        source: root.src
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 900
        sourceSize.height: 900
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: 30
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        visible: root.src !== ""
        source: img
        maskEnabled: true
        maskSource: mask
    }
    Text {
        anchors.centerIn: parent
        width: parent.width - 32
        visible: root.src === ""
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: "Long-press the home screen, then tap \u270e on this frame to pick photos"
        color: Theme.dim
        font.pixelSize: 13
    }
    MouseArea {
        anchors.fill: parent
        onClicked: if (root.photos.length > 1) root.idx = (root.idx + 1) % root.photos.length
    }
}
