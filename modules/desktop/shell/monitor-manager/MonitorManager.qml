// Standalone Monitor Manager window.
//
//   quickshell -p MonitorManager.qml
//
// Self-contained on purpose: qs.* QML modules only resolve from inside the
// iNiR runtime dir, so this window must not import them to stay launchable
// from anywhere. The wrapper (inir-monitor-manager) sets MONITOR_MANAGER_PY.
import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window

    width: 1180
    height: 820
    minimumWidth: 820
    minimumHeight: 620
    visible: true
    title: "Monitor Manager"
    color: "#14161a"

    MonitorManagerPane {
        id: pane
        anchors.fill: parent
        anchors.margins: 14
    }

    Shortcut {
        sequences: [StandardKey.Close, "Escape"]
        onActivated: window.close()
    }

    Shortcut {
        sequences: [StandardKey.Refresh]
        onActivated: pane.refresh()
    }
}
