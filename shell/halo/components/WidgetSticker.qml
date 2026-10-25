import QtQuick
import qs.services

// Sticker: an image (any file under ~/Pictures, PNG with transparency works best) or a built-in glyph. No card.
Item {
    id: root
    property var inst: null
    readonly property var cfg: inst && inst.cfg ? inst.cfg : ({})
    readonly property string src: cfg.src ? "file://" + cfg.src : ""
    readonly property string glyph: cfg.glyph || ""

    Image {
        anchors.fill: parent
        anchors.margins: 4
        visible: root.src !== ""
        source: root.src
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        sourceSize.width: 700
        sourceSize.height: 700
    }
    Text {
        anchors.centerIn: parent
        visible: root.glyph !== ""
        text: root.glyph
        color: Theme.accent
        font.pixelSize: Math.min(root.width, root.height) * 0.8
    }
    Text {
        anchors.centerIn: parent
        visible: root.src === "" && root.glyph === "" && Home.editing
        text: "\u270e"
        color: Theme.dim
        font.pixelSize: 28
    }
}
