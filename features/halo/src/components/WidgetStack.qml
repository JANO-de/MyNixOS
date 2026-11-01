import QtQuick
import qs.services

// Smart stack: tap the dots or the bottom corners to flip between widgets.
Item {
    id: root
    property var inst: null // set by WidgetHost; cfg.items = chosen member types
    property int cur: 0
    readonly property var items: (inst && inst.cfg && inst.cfg.items && inst.cfg.items.length) ? inst.cfg.items : Home.stackItems
    onItemsChanged: if (cur >= items.length) cur = 0

    Loader {
        id: ld
        anchors.fill: parent
        anchors.bottomMargin: 14
        source: {
            const t = Home.typeOf(root.items[root.cur]);
            return t ? "Widget" + t.comp + ".qml" : "";
        }
    }

    // Dots: tap one to jump to it.
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        spacing: 8

        Repeater {
            model: root.items.length

            Rectangle {
                required property int index
                width: 8
                height: 8
                radius: 4
                color: index === root.cur ? Theme.text : Qt.rgba(1, 1, 1, 0.3)
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    onClicked: root.cur = parent.index
                }
            }
        }
    }

    // Edge buttons so flipping never conflicts with the page swipe.
    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: 28
        height: 14
        color: "transparent"
        MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: root.cur = (root.cur + root.items.length - 1) % root.items.length }
    }
    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 28
        height: 14
        color: "transparent"
        MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: root.cur = (root.cur + 1) % root.items.length }
    }
}
