import QtQuick
import Quickshell
import qs.services

// Year progress ring.
Item {
    id: root
    readonly property real s: Math.min(width, height)
    readonly property date now: clock.date
    readonly property real frac: {
        const y = now.getFullYear();
        const a = new Date(y, 0, 1).getTime();
        const b = new Date(y + 1, 0, 1).getTime();
        return (now.getTime() - a) / (b - a);
    }

    SystemClock { id: clock; precision: SystemClock.Hours }

    Canvas {
        id: cv
        anchors.centerIn: parent
        width: root.s * 0.86
        height: width
        onPaint: {
            const c = getContext("2d");
            c.reset();
            const r = width / 2 - 6;
            c.lineWidth = 9;
            c.lineCap = "round";
            c.strokeStyle = "rgba(255,255,255,0.14)";
            c.beginPath();
            c.arc(width / 2, height / 2, r, 0, Math.PI * 2);
            c.stroke();
            c.strokeStyle = String(Theme.accent);
            c.beginPath();
            c.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * root.frac);
            c.stroke();
        }
        Connections {
            target: root
            function onFracChanged() { cv.requestPaint(); }
        }
        Component.onCompleted: requestPaint()
    }
    Text {
        anchors.centerIn: parent
        text: Math.floor(root.frac * 100) + "%"
        color: Theme.text
        font.pixelSize: root.s * 0.22
        font.weight: Font.Light
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        text: root.now.getFullYear()
        color: Theme.dim
        font.pixelSize: Math.max(11, root.s * 0.08)
    }
}
