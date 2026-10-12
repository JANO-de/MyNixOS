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
    // Material Symbols glyph chosen from a condition text
    function iconFor(cond) {
        const c = (cond || "").toLowerCase();
        if (c.indexOf("thunder") >= 0) return "thunderstorm";
        if (c.indexOf("snow") >= 0 || c.indexOf("sleet") >= 0) return "weather_snowy";
        if (c.indexOf("rain") >= 0 || c.indexOf("drizzle") >= 0 || c.indexOf("shower") >= 0) return "rainy";
        if (c.indexOf("fog") >= 0 || c.indexOf("mist") >= 0) return "foggy";
        if (c.indexOf("overcast") >= 0 || c.indexOf("cloud") >= 0) return c.indexOf("partly") >= 0 ? "partly_cloudy_day" : "cloud";
        return "sunny";
    }
    readonly property string icon: iconFor(cond)

    // Forecast detail for the weather panel (wttr.in j1 JSON). null until loaded.
    //   { place, feels, humidity, wind, windDir, pressure, uv, hours: [{time, temp, cond, rain}], days: [{date, hi, lo, cond}] }
    property var detail: null
    readonly property bool us: Config.island.units === "u"
    readonly property string unitT: us ? "°F" : "°C"
    readonly property string unitW: us ? "mph" : "km/h"

    readonly property string loc: Config.island.location
    onUsChanged: fetchDetail.running = true
    onLocChanged: { fetch.running = true; fetchDetail.running = true }

    Timer { interval: 1800000; repeat: true; running: true; triggeredOnStart: true; onTriggered: { fetch.running = true; fetchDetail.running = true } }
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

    Process {
        id: fetchDetail
        command: ["curl", "-sf", "--max-time", "15", "https://wttr.in/" + encodeURIComponent(root.loc) + "?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text), c = j.current_condition[0], us = root.us;
                    const hours = [];
                    j.weather.slice(0, 2).forEach((d, di) => d.hourly.forEach(h => {
                        const hh = Math.floor(Number(h.time) / 100);
                        const t = new Date(); t.setHours(hh, 0, 0, 0); t.setDate(t.getDate() + di);
                        if (t.getTime() > Date.now() - 3 * 3600000)
                            hours.push({ time: (hh < 10 ? "0" : "") + hh + ":00", temp: us ? h.tempF : h.tempC,
                                         cond: h.weatherDesc[0].value, rain: h.chanceofrain });
                    }));
                    root.detail = {
                        place: j.nearest_area && j.nearest_area[0] ? j.nearest_area[0].areaName[0].value : "",
                        feels: us ? c.FeelsLikeF : c.FeelsLikeC, humidity: c.humidity,
                        wind: us ? c.windspeedMiles : c.windspeedKmph, windDir: c.winddir16Point,
                        pressure: c.pressure, uv: c.uvIndex, cond: c.weatherDesc[0].value,
                        hours: hours.slice(0, 8),
                        days: j.weather.map(d => ({ date: d.date, hi: us ? d.maxtempF : d.maxtempC, lo: us ? d.mintempF : d.mintempC,
                                                    cond: d.hourly[4] ? d.hourly[4].weatherDesc[0].value : "" }))
                    };
                } catch (e) { console.warn("Weather: could not parse forecast", e) }
            }
        }
    }
}
