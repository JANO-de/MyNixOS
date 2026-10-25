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
    property color glassStroke: Qt.rgba(1, 1, 1, 0.14)
    property color text: "#ffffff"
    property color dim: "#8e8e93"
    property color accent: "#a6c8ff"
    readonly property int radius: 26
    readonly property string dir: Quickshell.env("HOME") + "/.config/halo"

    function rgba(hex, a) {
        const c = Qt.color(hex);
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function applyDefaults() {
        glass = Qt.rgba(0.13, 0.13, 0.16, 0.62);
        dim = "#8e8e93";
        accent = "#a6c8ff";
    }

    function applyColors(c) {
        if (c.primary)
            accent = c.primary;
        if (c.surface_container)
            glass = rgba(c.surface_container, 0.62);
        else if (c.surface)
            glass = rgba(c.surface, 0.62);
        if (c.on_surface_variant)
            dim = c.on_surface_variant;
    }

    // matugen JSON differs between versions: {colors:{dark:{role:"#hex"}}} or {colors:{role:{dark:"#hex"}}}.
    function val(x) {
        if (typeof x === "string")
            return x;
        if (!x)
            return null;
        return x.hex || x.color || (x.dark ? val(x.dark) : null) || (x.default ? val(x.default) : null);
    }

    function pick(j) {
        const c = j.colors || j;
        const out = {};
        for (const role of ["primary", "surface_container", "surface", "on_surface_variant"]) {
            const v = c.dark ? val(c.dark[role]) : val(c[role]);
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
        command: ["sh", "-c", "command -v matugen >/dev/null || exit 0; matugen image \"$1\" -j hex --dry-run --source-color-index 0 -m dark 2>/dev/null || matugen image \"$1\" -j hex --dry-run --source-color-index 0 2>/dev/null", "halo-theme", src]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const colors = root.pick(JSON.parse(text));
                    if (colors.primary) {
                        root.applyColors(colors);
                        cache.setText(JSON.stringify(colors));
                    }
                } catch (e) {}
            }
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
