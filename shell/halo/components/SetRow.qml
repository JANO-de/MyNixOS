import QtQuick
import qs.services

// Settings: one row. Title + optional subtitle on the left, anything you put inside on the right
// (a SetSwitch, a value Text, a SetButton). `glyph` draws a round badge before the title.
Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property string glyph: ""
    property string icon: "" // icon name/path (Apps.iconSource); wins over glyph
    property bool chevron: false
    property bool tappable: true
    default property alias trailing: trail.data
    signal clicked

    width: parent ? parent.width : 600
    height: Math.max(64, texts.implicitHeight + 28)
    radius: 22
    color: tap.pressed && tappable ? Theme.surfacePress : Theme.tint(0.07)
    Behavior on color { ColorAnimation { duration: 90 } }

    readonly property bool hasLead: glyph !== "" || icon !== ""

    Rectangle {
        id: badge
        visible: root.hasLead
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        height: 40
        radius: 20
        color: root.icon !== "" ? "transparent" : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)

        Text {
            visible: root.icon === ""
            anchors.centerIn: parent
            text: root.glyph
            color: Theme.accent
            font.pixelSize: 20
        }
        Image {
            visible: root.icon !== ""
            anchors.fill: parent
            source: root.icon !== "" ? Apps.iconSource(root.icon) : ""
            sourceSize: Qt.size(80, 80)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }
    }

    Column {
        id: texts
        anchors.left: parent.left
        anchors.leftMargin: root.hasLead ? 70 : 24
        anchors.right: trail.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: root.title
            color: Theme.text
            font.pixelSize: 17
            elide: Text.ElideRight
        }
        Text {
            visible: root.subtitle !== ""
            width: parent.width
            text: root.subtitle
            color: Theme.dim
            font.pixelSize: 13
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }
    }

    Item {
        id: trail
        anchors.right: parent.right
        anchors.rightMargin: root.chevron ? 40 : 20
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }

    Text {
        visible: root.chevron
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        text: "›"
        color: Theme.dim
        font.pixelSize: 26
    }

    MouseArea {
        id: tap
        anchors.fill: parent
        z: -1
        enabled: root.tappable
        onClicked: root.clicked()
    }
}
