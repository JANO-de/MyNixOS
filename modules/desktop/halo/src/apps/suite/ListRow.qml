import QtQuick
import qs.common

// Touch row used by every suite list (same language as Settings rows): optional round badge or lead item,
// title + subtitle, trailing controls (put children inside, they go to the right).
//   ListRow { title: "x"; subtitle: "y"; icon: "bell"; onClicked: ...; Pill { icon: "trash"; flat: true } }
//   lead: [ Check { ... } ]  replaces the badge with any item.
Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property string letter: ""
    property int titleSize: 17
    property bool dimTitle: false
    property bool strike: false
    property color subtitleColor: AppTheme.dim
    property bool selected: false
    property bool tappable: true
    default property alias trailing: trail.data
    property alias lead: leadSlot.data
    signal clicked
    signal pressAndHold

    readonly property bool badged: icon !== "" || letter !== ""
    readonly property bool hasLead: badged || leadSlot.children.length > 0

    width: parent ? parent.width : 400
    height: Math.max(68, texts.implicitHeight + 26)
    radius: 22
    color: selected ? AppTheme.accentSoft : (tap.pressed && tappable ? AppTheme.cardHigh : AppTheme.card)
    scale: tap.pressed && tappable ? 0.98 : 1
    Behavior on color { ColorAnimation { duration: 90 } }
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

    MouseArea {
        id: tap
        anchors.fill: parent
        enabled: root.tappable
        onClicked: root.clicked()
        onPressAndHold: root.pressAndHold()
    }
    Badge {
        visible: root.badged
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        icon: root.icon
        letter: root.letter
    }
    Item {
        id: leadSlot
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
    Column {
        id: texts
        anchors.left: parent.left
        anchors.leftMargin: root.hasLead ? 28 + (root.badged ? 40 : leadSlot.width) : 20
        anchors.right: trail.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
            width: parent.width
            text: root.title
            color: root.dimTitle ? AppTheme.dim : AppTheme.text
            font.pixelSize: root.titleSize
            font.weight: root.titleSize > 24 ? Font.Light : Font.Normal
            font.strikeout: root.strike
            elide: Text.ElideRight
        }
        Text {
            visible: root.subtitle !== ""
            width: parent.width
            text: root.subtitle
            color: root.subtitleColor
            font.pixelSize: 13
            elide: Text.ElideRight
        }
    }
    Row {
        id: trail
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
    }
}
