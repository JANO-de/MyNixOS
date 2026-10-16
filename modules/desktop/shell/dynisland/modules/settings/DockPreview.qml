// Live miniature of the dock: follows Config.dock (icon size, magnification, radius, media card).
import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    width: parent ? parent.width : 600
    height: 120
    readonly property real k: 0.62                         // preview scale
    readonly property real ico: Config.dock.iconSize * k

    Rectangle {
        id: bg
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 6 }
        width: row.width + 28 + (Config.dock.media ? 150 : 0); height: ico + 22
        radius: Config.dock.radius * k + 4
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, Config.appearance.glassOpacity)
        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.2)
        Behavior on width { NumberAnimation { duration: 160 } }
        Rectangle { anchors.fill: parent; radius: parent.radius
                    gradient: Gradient { GradientStop { position: 0; color: "#1cffffff" } GradientStop { position: 0.55; color: "transparent" } } }
        Row {
            id: row; spacing: 8
            anchors { left: parent.left; leftMargin: 14; bottom: parent.bottom; bottomMargin: 11 }
            Repeater {
                model: 5
                Rectangle {
                    required property int index
                    readonly property real m: 1 + (Config.dock.magnification - 1) * (index === 2 ? 1 : index === 1 || index === 3 ? 0.35 : 0)
                    width: ico * m; height: width; radius: width * 0.26; anchors.bottom: parent.bottom
                    color: index === 2 ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35) : Theme.surfaceContainerHigh
                    border.width: 1; border.color: index === 2 ? Theme.primary : "#30ffffff"
                    Behavior on width { NumberAnimation { duration: 120 } }
                    Icon { anchors.centerIn: parent; name: index === 0 ? "apps" : "web_asset"; size: parent.width * 0.5; color: Theme.surfaceFg }
                }
            }
        }
        Rectangle {   // media card stand-in
            visible: Config.dock.media; width: 140; height: ico; radius: 12; color: "#80000000"
            border.width: 1; border.color: "#30ffffff"
            anchors { left: row.right; leftMargin: 12; bottom: parent.bottom; bottomMargin: 11 }
            Row { anchors.centerIn: parent; spacing: 8
                  Icon { name: "skip_previous"; size: 16; color: "white" }
                  Icon { name: "play_arrow"; size: 20; color: Theme.primary }
                  Icon { name: "skip_next"; size: 16; color: "white" } }
        }
    }
}
