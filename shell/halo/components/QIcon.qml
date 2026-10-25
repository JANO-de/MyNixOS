import QtQuick
import QtQuick.Shapes

// Line icon (48 grid, round strokes) for the shade / quick settings, tinted with `color`.
Item {
    id: r

    property string name: ""
    property color color: "#ffffff"
    property real size: 24
    property bool filled: false

    readonly property var p: ({
        wifi: "M6 20 A26 26 0 0 1 42 20 M12 27 A17 17 0 0 1 36 27 M18 34 A8 8 0 0 1 30 34 M24 40 L24 40.5",
        bluetooth: "M13 17 L35 33 L24 42 V6 L35 15 L13 31",
        airplane: "M24 6 C26 6 27 8 27 10 V19 L42 28 V32 L27 28 V37 L32 41 V43 L24 41 L16 43 V41 L21 37 V28 L6 32 V28 L21 19 V10 C21 8 22 6 24 6 Z",
        moon: "M38 28 A16 16 0 1 1 20 10 A12 12 0 0 0 38 28 Z",
        rotation: "M38 22 A14 14 0 0 0 12 18 M12 10 V18 H20 M10 26 A14 14 0 0 0 36 30 M36 38 V30 H28",
        tablet: "M11 6 H37 V42 H11 Z M21 36 H27",
        monitor: "M6 10 H42 V32 H6 Z M16 40 H32 M24 32 V40",
        keyboard: "M5 14 H43 V34 H5 Z M11 21 H12 M18 21 H19 M25 21 H26 M32 21 H33 M39 21 H40 M14 28 H34",
        screenshot: "M6 16 V6 H16 M32 6 H42 V16 M42 32 V42 H32 M16 42 H6 V32 M17 17 H31 V31 H17 Z",
        lock: "M10 22 H38 V42 H10 Z M16 22 V15 A8 8 0 0 1 32 15 V22 M24 30 V34",
        gear: "M12 24 A12 12 0 1 0 36 24 A12 12 0 1 0 12 24 M19 24 A5 5 0 1 0 29 24 A5 5 0 1 0 19 24 M24 6 V12 M24 36 V42 M6 24 H12 M36 24 H42 M11.3 11.3 L15.5 15.5 M32.5 32.5 L36.7 36.7 M11.3 36.7 L15.5 32.5 M32.5 15.5 L36.7 11.3",
        sun: "M16 24 A8 8 0 1 0 32 24 A8 8 0 1 0 16 24 M24 5 V10 M24 38 V43 M5 24 H10 M38 24 H43 M10.6 10.6 L14.1 14.1 M37.4 10.6 L33.9 14.1 M10.6 37.4 L14.1 33.9 M37.4 37.4 L33.9 33.9",
        volume: "M8 19 H15 L26 10 V38 L15 29 H8 Z M32 18 A9 9 0 0 1 32 30 M36 12 A16 16 0 0 1 36 36",
        mute: "M8 19 H15 L26 10 V38 L15 29 H8 Z M33 19 L43 29 M43 19 L33 29",
        edit: "M8 40 L10 31 L32 9 L39 16 L17 38 Z M28 13 L35 20",
        check: "M10 25 L20 35 L38 14",
        plus: "M24 10 V38 M10 24 H38",
        minus: "M12 24 H36",
        sunset: "M8 34 H40 M14 34 A10 10 0 0 1 34 34 M24 10 V16 M10 18 L14 22 M38 18 L34 22 M12 42 H36",
        record: "M6 24 A18 18 0 1 0 42 24 A18 18 0 1 0 6 24 M17 24 A7 7 0 1 0 31 24 A7 7 0 1 0 17 24",
        region: "M6 14 V6 H14 M34 6 H42 V14 M42 34 V42 H34 M14 42 H6 V34 M24 18 V30 M18 24 H30",
        sleep: "M10 12 H22 L10 24 H22 M26 28 H36 L26 38 H36 M32 8 H40 L32 16 H40",
        restart: "M38 24 A14 14 0 1 1 33 13 M38 8 V16 H30",
        power: "M24 6 V24 M15 13 A16 16 0 1 0 33 13",
        bell: "M12 34 V22 A12 12 0 0 1 36 22 V34 L40 38 H8 Z M20 42 H28"
    })

    width: size
    height: size

    Shape {
        width: 48
        height: 48
        scale: r.size / 48
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: r.color
            strokeWidth: 2.8
            fillColor: r.filled ? r.color : "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: r.p[r.name] || "" }
        }
    }
}
