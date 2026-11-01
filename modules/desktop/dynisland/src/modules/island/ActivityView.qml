// Compact mode: current Live Activity (icon + label + progress), iOS-26-style.
// Tapping expands to ActivityFullView; an X clears it. A dot strip at the
// bottom shows how many activities are queued when there's more than one.
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

Item {
    id: v
    property bool active: false
    anchors.fill: parent
    opacity: active ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
    readonly property var a: Activities.current

    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 10 }
        spacing: 8
        Rectangle {
            Layout.preferredWidth: 26; Layout.preferredHeight: 26; radius: 13
            color: v.a && v.a.color ? v.a.color : Theme.primary
            Icon { anchors.centerIn: parent; name: v.a ? v.a.icon : "bolt"; size: 15; color: "white" }
        }
        Text { Layout.fillWidth: true; elide: Text.ElideRight; text: v.a ? v.a.label : ""
               color: "white"; font.pixelSize: 13; font.weight: Font.Medium }
        // progress bar, or three breathing dots when indeterminate
        Item {
            Layout.preferredWidth: 46; Layout.preferredHeight: 10
            Rectangle {   // track
                visible: v.a && v.a.progress >= 0
                anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: "#33ffffff"
                Rectangle { height: parent.height; radius: 2; color: v.a && v.a.color ? v.a.color : Theme.primary
                            width: parent.width * Math.max(0, Math.min(1, v.a ? v.a.progress : 0))
                            Behavior on width { NumberAnimation { duration: 300 } } }
            }
            Row {
                visible: !v.a || v.a.progress < 0
                anchors.centerIn: parent; spacing: 3
                Repeater { model: 3
                    Rectangle { width: 4; height: 4; radius: 2; color: "#ccffffff"
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            PauseAnimation { duration: index * 150 }
                            NumberAnimation { from: 0.3; to: 1; duration: 450 }
                            NumberAnimation { from: 1; to: 0.3; duration: 450 }
                        }
                    }
                }
            }
        }
    }
    MouseArea { anchors.fill: parent; onClicked: UiState.islandPinned = true }

    Row {   // queue dots, only when more than one activity is live
        visible: Activities.list.length > 1
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 3 }
        spacing: 3
        Repeater {
            model: Activities.list.length
            Rectangle { width: 4; height: 4; radius: 2; color: index === Activities.cursor ? "white" : "#55ffffff" }
        }
    }
}
