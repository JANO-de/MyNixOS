import QtQuick
import Quickshell
import qs.services

// Moon phase (mean synodic month, good to about a day).
Item {
    id: root
    readonly property real s: Math.min(width, height)
    readonly property real age: {
        const jd = clock.date.getTime() / 86400000 + 2440587.5;
        const p = ((jd - 2451550.1) / 29.530588853) % 1;
        return p < 0 ? p + 1 : p;
    }
    readonly property string name: {
        const p = age;
        if (p < 0.03 || p > 0.97) return "New moon";
        if (p < 0.22) return "Waxing crescent";
        if (p < 0.28) return "First quarter";
        if (p < 0.47) return "Waxing gibbous";
        if (p < 0.53) return "Full moon";
        if (p < 0.72) return "Waning gibbous";
        if (p < 0.78) return "Last quarter";
        return "Waning crescent";
    }

    SystemClock { id: clock; precision: SystemClock.Hours }

    Canvas {
        id: cv
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.s * 0.05
        width: root.s * 0.7
        height: width
        onPaint: {
            const c = getContext("2d");
            c.reset();
            const R = width / 2 - 2;
            const cx = width / 2;
            const cy = height / 2;
            c.fillStyle = "rgba(255,255,255,0.12)";
            c.beginPath();
            c.arc(cx, cy, R, 0, Math.PI * 2);
            c.fill();
            const p = root.age;
            const waxing = p < 0.5;
            const k = Math.cos(p * Math.PI * 2); // 1 new .. -1 full
            c.fillStyle = "#f2efe4";
            c.beginPath();
            // lit limb: right half when waxing, left half when waning
            c.arc(cx, cy, R, -Math.PI / 2, Math.PI / 2, !waxing);
            // terminator: half ellipse from the bottom back to the top
            const X = (waxing ? 1 : -1) * k * R;
            const steps = 40;
            for (let i = 0; i <= steps; i++) {
                const a = Math.PI / 2 - Math.PI * i / steps;
                c.lineTo(cx + X * Math.cos(a), cy + R * Math.sin(a));
            }
            c.closePath();
            c.fill();
        }
        Connections {
            target: root
            function onAgeChanged() { cv.requestPaint(); }
        }
        Component.onCompleted: requestPaint()
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.name
        color: Theme.dim
        font.pixelSize: Math.max(11, root.s * 0.09)
    }
}
