// Weather via wttr.in (no API key). Refreshes every 30 min.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root
    property string temp: "--"
    property string cond: ""
    // Material Symbols glyph chosen from the condition text
    readonly property string icon: {
        const c = cond.toLowerCase();
        if (c.indexOf("thunder") >= 0) return "thunderstorm";
        if (c.indexOf("snow") >= 0 || c.indexOf("sleet") >= 0) return "weather_snowy";
        if (c.indexOf("rain") >= 0 || c.indexOf("drizzle") >= 0 || c.indexOf("shower") >= 0) return "rainy";
        if (c.indexOf("fog") >= 0 || c.indexOf("mist") >= 0) return "foggy";
        if (c.indexOf("overcast") >= 0 || c.indexOf("cloud") >= 0) return c.indexOf("partly") >= 0 ? "partly_cloudy_day" : "cloud";
        return "sunny";
    }

    readonly property string loc: Config.island.location
    onLocChanged: fetch.running = true

    Timer { interval: 1800000; repeat: true; running: true; triggeredOnStart: true; onTriggered: fetch.running = true }
    Process {
        id: fetch
        command: ["curl", "-sf", "--max-time", "10",
                  "https://wttr.in/" + encodeURIComponent(root.loc) + "?format=%t|%C&" + Config.island.units]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split("|");
                if (p.length >= 2) { root.temp = p[0].replace("+", ""); root.cond = p[1] }
            }
        }
    }
}
