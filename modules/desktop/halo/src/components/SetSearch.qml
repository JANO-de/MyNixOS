import QtQuick
import qs.services

// Settings: search field (SetInput with a magnifier). Binds `text`; accepted() on Enter.
SetInput {
    id: root

    width: parent ? parent.width : 600
    placeholder: "Search settings"

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        text: "⌕"
        color: Theme.dim
        font.pixelSize: 22
    }
}
