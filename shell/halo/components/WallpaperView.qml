import QtQuick
import qs.services

// Renders a wallpaper spec ("preset:<id>" or "file:<path>") at any size.
Item {
    id: root

    property string spec: ""
    readonly property var preset: spec.indexOf("preset:") === 0 ? Wallpaper.preset(spec.substring(7)) : null
    readonly property bool isFile: spec.indexOf("file:") === 0
    readonly property bool isTopo: preset !== null && preset.kind === "topo"
    readonly property bool isGradient: preset !== null && preset.kind === "gradient"

    clip: true

    Rectangle {
        anchors.fill: parent
        visible: !root.isFile
        color: root.isTopo ? root.preset.bg : "#101014"
    }

    Rectangle {
        anchors.fill: parent
        visible: root.isGradient
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.isGradient ? root.preset.c1 : "#000000" }
            GradientStop { position: 1.0; color: root.isGradient ? root.preset.c2 : "#000000" }
        }
    }

    Canvas {
        id: cv
        anchors.fill: parent
        visible: root.isTopo
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: requestPaint()
        Component.onCompleted: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!root.isTopo || width < 2)
                return;
            const w = width;
            const h = height;
            ctx.strokeStyle = root.preset.line;
            ctx.globalAlpha = 0.55;
            ctx.lineWidth = Math.max(1, w / 650);
            const n = 34;
            for (let i = 0; i < n; i++) {
                ctx.beginPath();
                const y0 = (i / (n - 1)) * h * 1.15 - h * 0.075;
                for (let x = 0; x <= w; x += w / 90) {
                    const u = x / w;
                    const y = y0 + h * 0.06 * Math.sin(u * 5.0 + i * 0.31) + h * 0.035 * Math.sin(u * 11.0 - i * 0.17) + h * 0.05 * Math.sin(u * 2.3 + i * 0.05);
                    if (x === 0)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                ctx.stroke();
            }
        }
    }

    Image {
        anchors.fill: parent
        visible: root.isFile
        source: root.isFile ? "file://" + root.spec.substring(5) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: Math.max(1, root.width * 2)
    }
}
