import QtQuick
import qs.common

// Popup menu with submenus + scrolling. popup(x, y, [{id,label,ico,danger,disabled,sub:[...]} | {sep:true}]); emits picked(id).
Item {
    id: root
    property var items: []
    property var stack: []
    property real px: 0
    property real py: 0
    signal picked(string id)
    visible: false
    anchors.fill: parent
    z: 100

    function popup(x, y, list) {
        stack = [];
        items = list;
        px = x;
        py = y;
        visible = true;
    }
    function choose(m) {
        if (m.sub) {
            stack = stack.concat([items]);
            items = [{ id: "__back", label: "\u2039  " + m.label }].concat(m.sub);
        } else if (m.id === "__back") {
            items = stack[stack.length - 1];
            stack = stack.slice(0, -1);
        } else {
            visible = false;
            picked(m.id);
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: root.visible = false
    }
    Rectangle {
        id: box
        width: 270
        height: Math.min(col.implicitHeight + 16, root.height - 16)
        radius: 24
        color: AppTheme.cardHigh
        border.width: 1
        border.color: AppTheme.line
        x: Math.max(8, Math.min(root.px, root.width - width - 8))
        y: Math.max(8, Math.min(root.py, root.height - height - 8))
        scale: root.visible ? 1 : 0.9
        transformOrigin: Item.TopLeft
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

        Flickable {
            anchors.fill: parent
            anchors.margins: 8
            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: col
                width: parent.width
                Repeater {
                    model: root.items
                    Item {
                        id: it
                        required property var modelData
                        readonly property bool hasIco: (modelData.ico || "") !== ""
                        width: col.width
                        height: modelData.sep ? 9 : 42
                        Rectangle {
                            visible: it.modelData.sep === true
                            anchors.centerIn: parent
                            width: parent.width - 16
                            height: 1
                            color: AppTheme.line
                        }
                        Rectangle {
                            visible: it.modelData.sep !== true
                            anchors.fill: parent
                            radius: 16
                            color: mm.pressed ? AppTheme.accentSoft : "transparent"
                            opacity: it.modelData.disabled ? 0.35 : 1
                            Ico {
                                visible: it.hasIco
                                x: 14
                                anchors.verticalCenter: parent.verticalCenter
                                name: it.modelData.ico || ""
                                size: 20
                                color: it.modelData.danger ? "#ff8a80" : AppTheme.dim
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                x: it.hasIco ? 44 : 14
                                width: parent.width - x - 30
                                elide: Text.ElideRight
                                text: it.modelData.label || ""
                                color: it.modelData.danger ? "#ff8a80" : AppTheme.text
                                font.pixelSize: 15
                            }
                            Ico {
                                visible: it.modelData.sub !== undefined
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                name: "fwd"
                                size: 16
                                color: AppTheme.dim
                            }
                            MouseArea {
                                id: mm
                                anchors.fill: parent
                                enabled: it.modelData.sep !== true && it.modelData.disabled !== true
                                onClicked: root.choose(it.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
