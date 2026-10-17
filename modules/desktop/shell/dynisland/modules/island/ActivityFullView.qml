// Expanded mode (hover/tap on a Live Activity): every active activity, stacked,
// each with its progress bar and a dismiss button.
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

Item {
    id: v
    property bool active: false
    anchors.centerIn: parent
    width: Config.island.fullWidth - 40
    height: Config.island.fullHeight - 40
    opacity: active ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    ColumnLayout {
        anchors.fill: parent; spacing: 10
        Text { text: "Live Activities"; color: "#99ffffff"; font.pixelSize: 12; font.weight: Font.DemiBold }
        Repeater {
            model: Activities.list
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true; spacing: 10
                Rectangle { Layout.preferredWidth: 34; Layout.preferredHeight: 34; radius: 17
                            color: modelData.color ? modelData.color : Theme.primary
                            Icon { anchors.centerIn: parent; name: modelData.icon; size: 18; color: "white" } }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 3
                    Text { Layout.fillWidth: true; elide: Text.ElideRight; text: modelData.label; color: "white"; font.pixelSize: 14 }
                    Rectangle {
                        visible: modelData.progress >= 0
                        Layout.fillWidth: true; Layout.preferredHeight: 5; radius: 2.5; color: "#33ffffff"
                        Rectangle { height: parent.height; radius: 2.5; color: modelData.color ? modelData.color : Theme.primary
                                    width: parent.width * Math.max(0, Math.min(1, modelData.progress))
                                    Behavior on width { NumberAnimation { duration: 300 } } }
                    }
                }
                IconButton { icon: "close"; diameter: 26; iconSize: 14; onClicked: Activities.clear(modelData.id) }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
