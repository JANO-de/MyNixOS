import QtQuick
import qs.services

// Glass card around one widget. Long-press enters edit mode; "-" removes it.
Item {
    id: root

    required property string wid

    scale: Home.editing ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    SequentialAnimation on rotation {
        running: Home.editing
        loops: Animation.Infinite
        NumberAnimation { to: 0.8; duration: 120 }
        NumberAnimation { to: -0.8; duration: 120 }
        onRunningChanged: if (!running) root.rotation = 0
    }

    Rectangle {
        anchors.fill: parent
        radius: 30
        color: Theme.glass
        border.color: Theme.glassStroke
        border.width: 1
    }

    MouseArea {
        anchors.fill: parent
        onPressAndHold: Home.editing = true
    }

    Loader {
        anchors.fill: parent
        anchors.margins: 16
        sourceComponent: root.wid === "clock" ? clockC
            : root.wid === "calendar" ? calendarC
            : root.wid === "battery" ? batteryC
            : root.wid === "media" ? mediaC : null
    }

    Component { id: clockC; WidgetClock {} }
    Component { id: calendarC; WidgetCalendar {} }
    Component { id: batteryC; WidgetBattery {} }
    Component { id: mediaC; WidgetMedia {} }

    Rectangle {
        visible: Home.editing
        x: -6
        y: -6
        width: 30
        height: 30
        radius: 15
        color: "#3a3a3c"
        border.color: Qt.rgba(1, 1, 1, 0.3)
        border.width: 1

        Rectangle {
            anchors.centerIn: parent
            width: 12
            height: 2
            radius: 1
            color: Theme.text
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            onClicked: Home.removeWidget(root.wid)
        }
    }
}
