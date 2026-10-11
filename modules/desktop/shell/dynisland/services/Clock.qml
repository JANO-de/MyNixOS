// Formatted time/date strings. Ticks once a minute (cheap).
pragma Singleton
import QtQuick
import Quickshell
import qs.config

Singleton {
    readonly property var date: sc.date
    readonly property string time: Qt.formatDateTime(sc.date, Config.island.use24h ? "HH:mm" : "h:mm AP")
    readonly property string dayShort: Qt.formatDateTime(sc.date, "ddd d")
    readonly property string dateLong: Qt.formatDateTime(sc.date, "dddd, d MMMM")
    SystemClock { id: sc; precision: SystemClock.Minutes }
}
