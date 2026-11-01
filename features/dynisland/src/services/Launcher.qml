// =============================================================================
//  Launcher — the data/logic behind the app drawer (UI: modules/launcher/).
//
//   apps          every installed app (DesktopEntries), with an auto category
//   usage         launch counts + last launch time, saved in ~/.config/dynisland/usage.json
//   list(q,cat,m) the apps to show: fuzzy search, or a category, or "Frequent"
//   calc(q)       tiny calculator: "2*(3+4)" -> "14"   (empty string if q is not math)
//   record(id)    call after launching: this is what makes the list auto-sort
// =============================================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    // ---- usage tracking (what makes the list "auto-sort") -----------------------
    property var usage: ({})                         // { desktopId: { n: launches, t: lastLaunchMs } }
    FileView {
        id: fv
        path: Config.dir + "/usage.json"
        onLoaded: { try { root.usage = JSON.parse(text()) } catch (e) { console.warn("Launcher: bad usage.json", e) } }
    }
    function record(id) {
        const u = Object.assign({}, usage), c = u[id] || { n: 0, t: 0 };
        u[id] = { n: c.n + 1, t: Date.now() };
        usage = u;
        fv.setText(JSON.stringify(u));
    }
    // launches, fading with age (half-weight after ~2 weeks without use)
    function score(id) {
        const c = usage[id];
        return c ? c.n / (1 + (Date.now() - c.t) / 864e5 / 14) : 0;
    }

    // ---- categories: freedesktop "Categories=" -> a friendly group ---------------------
    // Order = priority (an app in several categories lands in the first match).
    readonly property var catDefs: [
        { name: "Games",       icon: "sports_esports", keys: ["Game"] },
        { name: "Development", icon: "code",           keys: ["Development", "IDE", "Debugger"] },
        { name: "Graphics",    icon: "palette",        keys: ["Graphics", "Photography"] },
        { name: "Office",      icon: "description",    keys: ["Office", "TextEditor", "Spreadsheet", "WordProcessor", "Presentation"] },
        { name: "Internet",    icon: "language",       keys: ["Network", "WebBrowser", "Email", "InstantMessaging", "Chat", "FileTransfer"] },
        { name: "Media",       icon: "play_circle",    keys: ["AudioVideo", "Audio", "Video", "Music", "Player"] },
        { name: "System",      icon: "settings",       keys: ["System", "Settings", "PackageManager", "Monitor"] },
        { name: "Utilities",   icon: "build",          keys: ["Utility", "Accessibility", "Archiving", "Calculator", "FileManager", "TerminalEmulator"] }
    ]
    function categoryOf(e) {
        const cs = Array.from(e.categories || []);
        for (const d of catDefs) if (d.keys.some(k => cs.indexOf(k) >= 0)) return d.name;
        return "Other";
    }

    // ---- the app list ------------------------------------------------------------------
    readonly property var apps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .map(e => ({
            entry: e, id: e.id, name: e.name, cat: categoryOf(e),
            nameL: (e.name || "").toLowerCase(),
            genL: (e.genericName || "").toLowerCase(),
            kwL: Array.from(e.keywords || []).join(" ").toLowerCase(),
            comL: (e.comment || "").toLowerCase()
        }))
    // only categories that have apps, in catDefs order, "Other" last
    readonly property var categoryNames: {
        const have = {};
        for (const a of apps) have[a.cat] = true;
        const out = catDefs.filter(d => have[d.name]).map(d => d.name);
        if (have["Other"]) out.push("Other");
        return out;
    }

    // icon file for an app (theme name or absolute path), generic icon as fallback
    function iconFor(entry) {
        const n = entry ? entry.icon : "";
        if (n && n.charAt(0) === "/") return "file://" + n;
        return (n && Quickshell.iconPath(n, true)) || Quickshell.iconPath("application-x-executable");
    }

    // ---- fuzzy search ---------------------------------------------------------------------
    // prefix 100, word start 85, inside 60, letters in order ("ff" -> firefox) 10..35, no match -1
    function fz(q, t) {
        if (!t) return -1;
        const i = t.indexOf(q);
        if (i === 0) return 100;
        if (i > 0) return (t[i - 1] === " " || t[i - 1] === "-") ? 85 : 60;
        if (q.length < 2) return -1;
        let qi = 0, last = -2, sc = 0;
        for (let ti = 0; ti < t.length && qi < q.length; ti++)
            if (t[ti] === q[qi]) { sc += (ti === last + 1) ? 3 : 1; last = ti; qi++ }
        return qi === q.length ? 10 + Math.min(sc, 25) : -1;
    }

    // cat: "All" | "Frequent" | a category name.  mode: "auto" (by usage) | "az".
    // With a query the category is ignored (search everything).
    function list(query, cat, mode) {
        const q = (query || "").trim().toLowerCase();
        if (q.charAt(0) === ">") return [];          // ">" = run a shell command, no app results
        const out = [];
        for (const a of apps) {
            const sc = score(a.id);
            if (q) {
                const s = Math.max(fz(q, a.nameL), 0.8 * fz(q, a.genL), 0.7 * fz(q, a.kwL), 0.4 * fz(q, a.comL));
                if (s <= 0) continue;
                out.push({ a: a, s: s + Math.min(sc, 5) * 2 });
            } else {
                if (cat === "Frequent") { if (sc <= 0) continue }
                else if (cat !== "All" && a.cat !== cat) continue;
                out.push({ a: a, s: (mode === "az" && cat !== "Frequent") ? 0 : sc });
            }
        }
        out.sort((x, y) => (y.s - x.s) || x.a.name.localeCompare(y.a.name));
        return out.slice(0, q === "" && cat === "Frequent" ? 24 : 400).map(o => o.a);
    }

    // ---- calculator -----------------------------------------------------------------------
    // Only digits, + - * / % ^ ( ) . and a few Math functions pass the whitelist, so eval is safe.
    function calc(q) {
        let s = (q || "").toLowerCase().replace(/\s+/g, "").replace(/,/g, ".");
        if (!/\d/.test(s) || !/[-+*\/%^()]|sqrt|sin|cos|tan|log|ln|abs|round|floor|ceil|pi/.test(s)) return "";
        s = s.replace(/\^/g, "**")
             .replace(/sqrt|sin|cos|tan|log|ln|abs|round|floor|ceil/g, m => "Math." + (m === "ln" ? "log" : m === "log" ? "log10" : m))
             .replace(/pi/g, "Math.PI");
        if (!/^[0-9+\-*\/().%]*$/.test(s.replace(/Math\.(log10|log|sqrt|sin|cos|tan|abs|round|floor|ceil|PI)/g, ""))) return "";
        try {
            const v = eval(s);
            return (typeof v === "number" && isFinite(v)) ? String(Math.round(v * 1e10) / 1e10) : "";
        } catch (e) { return "" }
    }

    // ---- dock pinning (same list the dock uses: Config.dock.pinned) ----------------
    function norm(s) { return (s || "").toLowerCase().replace(/\.desktop$/, "") }
    function isPinned(id) { return Array.from(Config.dock.pinned).some(x => norm(x) === norm(id)) }
    function togglePin(id) {
        const cur = Array.from(Config.dock.pinned);
        const i = cur.findIndex(x => norm(x) === norm(id));
        if (i >= 0) cur.splice(i, 1); else cur.push(id);
        Config.dock.pinned = cur;
    }
}
