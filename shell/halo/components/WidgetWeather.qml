import QtQuick
import qs.services

// Weather from wttr.in (location by IP). Tap to refresh.
Item {
    id: root
    readonly property var wx: WidgetData.wx
    readonly property real s: Math.min(width, height)

    Component.onCompleted: WidgetData.use("wx", 1)
    Component.onDestruction: WidgetData.use("wx", -1)

    Text {
        anchors.top: parent.top
        width: parent.width
        elide: Text.ElideRight
        text: root.wx.ok ? root.wx.loc : "Weather"
        color: Theme.dim
        font.pixelSize: Math.max(11, root.s * 0.09)
    }
    Text {
        anchors.centerIn: parent
        text: root.wx.ok ? root.wx.temp : "--"
        color: Theme.text
        font.pixelSize: root.s * 0.38
        font.weight: Font.Light
    }
    Text {
        anchors.bottom: parent.bottom
        width: parent.width
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        text: root.wx.ok ? root.wx.cond + (root.width > 200 ? "  \u00b7  " + root.wx.hum + "  \u00b7  " + root.wx.wind : "") : "No data (tap to retry)"
        color: Theme.dim
        font.pixelSize: Math.max(11, root.s * 0.09)
    }
    MouseArea {
        anchors.fill: parent
        onClicked: WidgetData.fetchWx()
    }
}
