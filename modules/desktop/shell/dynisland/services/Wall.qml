// Wallpaper helper: per-workspace wallpapers (Settings > Appearance).
//   Wall.currentPath    wallpaper of the active workspace (or the global one)
//   Wall.pathFor(output) same, for a given output name
//   Wall.set(path)      set the wallpaper (active workspace when per-workspace is on)
pragma Singleton
import QtQuick
import qs.config

QtObject {
    function keyFor(output) {
        const ws = Niri.workspaces.find(w => w.is_active && (!output || w.output === output));
        return ws ? (ws.name || String(ws.idx)) : "";
    }
    function pathFor(output) {
        const a = Config.appearance;
        if (a.perWorkspace) { const p = a.wsWallpapers[keyFor(output)]; if (p) return p }
        return a.wallpaper;
    }
    readonly property string currentPath: pathFor("")
    function set(path) {
        const a = Config.appearance;
        if (a.perWorkspace) {
            const k = keyFor("");
            if (k) { const m = Object.assign({}, a.wsWallpapers); m[k] = path; a.wsWallpapers = m }
        }
        a.wallpaper = path;   // also drives the theme (matugen)
    }
}
