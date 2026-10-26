pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Colours follow the wallpaper: for an image wallpaper, `matugen` (Material You) is run in the
// background and the accent / glass / dim colours are replaced; presets use the defaults.
// Last result is cached in ~/.config/halo/theme.json so the next start looks right immediately.
Singleton {
    id: root

    property color glass: Qt.rgba(0.13, 0.13, 0.16, 0.62)
    property bool light: false
    property color glassStroke: light ? Qt.rgba(0, 0, 0, 0.14) : Qt.rgba(1, 1, 1, 0.14)
    property color text: "#ffffff"
    property color dim: "#8e8e93"
    property color accent: "#a6c8ff"
    property color accentInk: "#0b1b33"
    property color accentInkDim: Qt.rgba(0.04, 0.11, 0.2, 0.7)
    property color surfaceHigh: Qt.rgba(0.11, 0.19, 0.2, 0.97)
    property color surfacePress: Qt.rgba(0.2, 0.32, 0.33, 0.98)
    property color scrim: Qt.rgba(0.04, 0.07, 0.08, 0.85)
    property color iconTile: Qt.rgba(1, 1, 1, 0.10)
    property color iconInk: "#ffffff" // unused (icons are really recoloured now)
    readonly property bool themedIcons: iconDir !== ""
    // Recoloured icon set (halo-recolor-icons): dir + { iconName: true }. Empty = stock icons.
    property string iconDir: ""
    property var iconNames: ({})
    property var pending: ({})
    readonly property var schemes: ["tonal-spot", "content", "expressive", "fidelity", "fruit-salad", "monochrome", "neutral", "rainbow"]
    property string scheme: "tonal-spot"

    function setScheme(n) {
        scheme = n;
        schemeFile.setText(JSON.stringify({ scheme: n, light: light }));
        regen();
    }
    readonly property int radius: 26
    readonly property string dir: Quickshell.env("HOME") + "/.config/halo"

    // White overlay on dark, black overlay on light: use instead of Qt.rgba(1, 1, 1, a).
    function tint(a) {
        return light ? Qt.rgba(0, 0, 0, a) : Qt.rgba(1, 1, 1, a);
    }

    function setLight(v) {
        light = v;
        schemeFile.setText(JSON.stringify({ scheme: scheme, light: v }));
        regen();
    }

    function rgba(hex, a) {
        const c = Qt.color(hex);
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function applyDefaults() {
        if (light) {
            glass = Qt.rgba(0.96, 0.96, 0.98, 0.72);
            text = "#1b1b1f";
            dim = "#5b5f66";
            accent = "#2b5fb0";
            accentInk = "#ffffff";
            accentInkDim = Qt.rgba(1, 1, 1, 0.7);
            surfaceHigh = Qt.rgba(0.92, 0.93, 0.96, 0.97);
            surfacePress = Qt.rgba(0.84, 0.86, 0.9, 0.98);
            scrim = Qt.rgba(0.97, 0.97, 0.99, 0.92);
            iconTile = Qt.rgba(0, 0, 0, 0.08);
        } else {
            glass = Qt.rgba(0.13, 0.13, 0.16, 0.62);
            text = "#ffffff";
            dim = "#8e8e93";
            accent = "#a6c8ff";
            accentInk = "#0b1b33";
            accentInkDim = Qt.rgba(0.04, 0.11, 0.2, 0.7);
            surfaceHigh = Qt.rgba(0.11, 0.19, 0.2, 0.97);
            surfacePress = Qt.rgba(0.2, 0.32, 0.33, 0.98);
            scrim = Qt.rgba(0.04, 0.07, 0.08, 0.85);
            iconTile = Qt.rgba(1, 1, 1, 0.10);
        }
        iconDir = "";
        iconNames = {};
    }

    function setIcons(dir, names) {
        const m = {};
        for (const n of names)
            m[n] = true;
        iconNames = m;
        iconDir = dir;
    }

    function applyColors(c) {
        text = c.on_surface ? c.on_surface : (light ? "#1b1b1f" : "#ffffff");
        if (c.primary)
            accent = c.primary;
        if (c.surface_container)
            glass = rgba(c.surface_container, 0.62);
        else if (c.surface)
            glass = rgba(c.surface, 0.62);
        if (c.on_surface_variant)
            dim = c.on_surface_variant;
        if (c.on_primary) {
            accentInk = c.on_primary;
            accentInkDim = rgba(c.on_primary, 0.7);
        }
        if (c.surface_container_high)
            surfaceHigh = rgba(c.surface_container_high, 0.97);
        if (c.surface_container_highest)
            surfacePress = rgba(c.surface_container_highest, 0.98);
        if (c.surface)
            scrim = rgba(c.surface, 0.88);
        if (c.surface_container_highest)
            iconTile = rgba(c.surface_container_highest, 0.9);
        if (c.icons && c.icons.dir)
            setIcons(c.icons.dir, c.icons.names || []);
    }

    function iconCmd(c) {
        const names = [];
        for (const e of DesktopEntries.applications.values) {
            const n = String(e.icon || "");
            if (n !== "" && n.charAt(0) !== "/")
                names.push(n);
        }
        return ["halo-recolor-icons", c.primary_container, c.primary, c.primary,
                Quickshell.env("HOME") + "/.cache/halo/icons/" + String(c.primary + c.primary_container).replace(/#/g, "")].concat(names);
    }

    // matugen JSON differs between versions: {colors:{dark:{role:"#hex"}}} or {colors:{role:{dark:"#hex"}}}.
    function val(x) {
        if (typeof x === "string")
            return x;
        if (!x)
            return null;
        return x.hex || x.color || (x[light ? "light" : "dark"] ? val(x[light ? "light" : "dark"]) : null) || (x.default ? val(x.default) : null);
    }

    function pick(j) {
        const c = j.colors || j;
        const out = {};
        for (const role of ["primary", "on_primary", "on_primary_container", "primary_container", "surface_container", "surface_container_high", "surface_container_highest", "surface", "on_surface_variant", "on_surface"]) {
            const m = light ? "light" : "dark";
            const v = c[m] ? val(c[m][role]) : val(c[role]);
            if (v)
                out[role] = v;
        }
        return out;
    }

    function regen() {
        const spec = Wallpaper.current;
        if (spec.indexOf("file:") !== 0) {
            applyDefaults();
            return;
        }
        gen.src = spec.substring(5);
        gen.scheme = scheme;
        gen.running = true;
    }

    Connections {
        target: Wallpaper
        function onCurrentChanged() {
            root.regen();
        }
    }

    Process {
        id: gen
        property string src: ""
        property string scheme: "tonal-spot"
        command: ["sh", "-c", "command -v matugen >/dev/null || exit 0; matugen image \"$1\" -j hex --dry-run --source-color-index 0 -m \"$3\" -t \"scheme-$2\" 2>/dev/null || matugen image \"$1\" -j hex --dry-run --source-color-index 0 2>/dev/null", "halo-theme", src, scheme, root.light ? "light" : "dark"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const colors = root.pick(JSON.parse(text));
                    if (colors.primary) {
                        root.applyColors(colors);
                        root.pending = colors;
                        cache.setText(JSON.stringify(colors));
                        if (colors.primary_container) {
                            icons.command = root.iconCmd(colors);
                            icons.running = true;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: icons
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const names = JSON.parse(text);
                    const dir = icons.command[4];
                    root.setIcons(dir, names);
                    cache.setText(JSON.stringify(Object.assign({}, root.pending, { icons: { dir: dir, names: names } })));
                } catch (e) {}
            }
        }
    }

    FileView {
        id: schemeFile
        path: root.dir + "/scheme.json"
        atomicWrites: true
        onLoaded: {
            try {
                const n = JSON.parse(text()).scheme;
                if (root.schemes.indexOf(n) >= 0)
                    root.scheme = n;
                if (JSON.parse(text()).light === true) {
                    root.light = true;
                    root.regen();
                }
            } catch (e) {}
        }
    }

    FileView {
        id: cache
        path: root.dir + "/theme.json"
        atomicWrites: true
        onLoaded: {
            try {
                root.applyColors(JSON.parse(text()));
            } catch (e) {}
        }
    }
}
