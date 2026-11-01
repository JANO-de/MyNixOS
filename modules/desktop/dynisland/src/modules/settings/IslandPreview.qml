// Live miniature of the island (idle and expanded), driven by Config.island.
import QtQuick
import qs.config
import qs.services

Item {
    width: parent ? parent.width : 600
    height: Config.island.fullHeight * 0.5 + Config.island.idleHeight * 0.8 + 40
    readonly property real k: Math.min(0.5, (width - 40) / Math.max(1, Config.island.fullWidth))

    component Pill: Rectangle {
        color: "black"; border.width: 1; border.color: Glass.outline
        anchors.horizontalCenter: parent.horizontalCenter
        Rectangle { anchors.fill: parent; radius: parent.radius
                    gradient: Gradient { GradientStop { position: 0; color: Glass.sheenTop } GradientStop { position: Glass.sheenStop; color: "transparent" } } }
        Behavior on width { NumberAnimation { duration: 160 } }
        Behavior on height { NumberAnimation { duration: 160 } }
    }
    Pill {   // idle
        y: 4; width: Config.island.idleWidth * k * 1.6; height: Config.island.idleHeight * k * 1.6
        radius: height / 2
    }
    Pill {   // expanded
        y: Config.island.idleHeight * k * 1.6 + 24
        width: Config.island.fullWidth * k; height: Config.island.fullHeight * k
        radius: Math.min(height / 2, (Config.island.fullRadius + Glass.radiusBoost) * k)
        Text { anchors.centerIn: parent; text: "Expanded"; color: "#99ffffff"; font.pixelSize: 13 }
    }
}
