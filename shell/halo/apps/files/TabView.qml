import QtQuick
import qs.common

// One tab: a pane, or two side by side (split view).
Item {
    id: tv
    required property var host
    required property int uid
    required property int index
    required property string start
    visible: index === host.cur
    property bool split: false
    property int activeIdx: 0
    readonly property var active: split && activeIdx === 1 ? p2 : p1
    readonly property var other: split ? (activeIdx === 1 ? p1 : p2) : null
    property alias first: p1
    property alias second: p2
    readonly property string paneTitle: active.title
    onPaneTitleChanged: host.setTabTitle(uid, paneTitle)
    onSplitChanged: {
        if (split && p2.path === "")
            p2.go(p1.path);
        if (!split)
            activeIdx = 0;
    }

    Pane {
        id: p1
        win: tv.host
        isActive: tv.activeIdx === 0
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: tv.split ? tv.width / 2 - 3 : tv.width
        Component.onCompleted: go(tv.start)
    }
    Rectangle {
        visible: tv.split
        x: tv.width / 2 - 1
        y: 12
        width: 2
        height: parent.height - 24
        radius: 1
        color: AppTheme.line
    }
    Pane {
        id: p2
        win: tv.host
        visible: tv.split
        isActive: tv.split && tv.activeIdx === 1
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: tv.width / 2 - 3
    }
}
