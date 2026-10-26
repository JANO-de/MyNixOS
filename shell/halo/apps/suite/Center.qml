import QtQuick

Item {
    id: root
    default property alias content: box.data
    width: parent ? parent.width : 0
    height: box.height
    Item {
        id: box
        anchors.horizontalCenter: parent.horizontalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
