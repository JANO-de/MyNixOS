// =============================================================================
//  PanelView — hosts the island panels ("panel" mode). The pill morphs to the size
//  listed in Island.qml (`panelSizes`) and shows panels/<Name>Panel.qml here.
//  Opened with UiState.openPanel("clock" | "weather" | "calendar" | "wifi" |
//  "bluetooth" | "audio" | "power" | "history"); closed by the X, Esc-less outside click.
//
//  TO ADD A PANEL: create panels/FooPanel.qml (root = PanelFrame), add it to `files`
//  here and a size to `panelSizes` in Island.qml, then open it with UiState.openPanel("foo").
// =============================================================================
import QtQuick
import qs.services

Item {
    id: v
    property bool active: false
    anchors.fill: parent
    opacity: active ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 180 } }

    readonly property var files: ({
        clock: "ClockPanel", weather: "WeatherPanel", calendar: "CalendarPanel", wifi: "WifiPanel",
        bluetooth: "BluetoothPanel", audio: "AudioPanel", power: "PowerPanel", history: "HistoryPanel", clipboard: "ClipboardPanel"
    })
    Loader {
        anchors.fill: parent
        active: v.active && UiState.panel !== ""
        source: v.files[UiState.panel] ? "panels/" + v.files[UiState.panel] + ".qml" : ""
    }
}
