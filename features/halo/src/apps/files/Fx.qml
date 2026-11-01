pragma Singleton
import QtQuick
import Quickshell

// Path / file-type helpers for the Files app.
Singleton {
    function base(p) {
        const i = p.lastIndexOf("/");
        return i < 0 ? p : p.substring(i + 1);
    }
    function dirOf(p) {
        const i = p.lastIndexOf("/");
        return i <= 0 ? "/" : p.substring(0, i);
    }
    function ext(n) {
        const i = n.lastIndexOf(".");
        return i <= 0 ? "" : n.substring(i + 1).toLowerCase();
    }
    function isArchive(n) {
        return /\.(zip|7z|tar|tar\.gz|tgz|tar\.xz|txz|tar\.zst|tar\.bz2|tbz2)$/i.test(n);
    }
    function kind(e) {
        if (e.dir)
            return "folder";
        const x = ext(e.name);
        if (["png", "jpg", "jpeg", "webp", "gif", "bmp", "svg"].indexOf(x) >= 0)
            return "image";
        if (["mp3", "flac", "ogg", "wav", "m4a", "opus"].indexOf(x) >= 0)
            return "audio";
        if (["mp4", "mkv", "webm", "mov", "avi"].indexOf(x) >= 0)
            return "video";
        if (x === "pdf")
            return "pdf";
        if (["js", "ts", "py", "c", "h", "cpp", "rs", "go", "sh", "qml", "nix", "lua", "json", "css", "html", "java", "toml", "yaml", "yml", "xml"].indexOf(x) >= 0)
            return "code";
        if (isArchive(e.name))
            return "archive";
        return "text";
    }
    function icon(k) {
        return { folder: "folder", image: "image-x-generic", audio: "audio-x-generic", video: "video-x-generic", pdf: "application-pdf", archive: "package-x-generic", code: "text-x-generic", text: "text-x-generic" }[k];
    }
    function ico(k) {
        return { folder: "folder", image: "image", audio: "music", video: "video", pdf: "pdf", archive: "archive", code: "code", text: "text" }[k] || "doc";
    }
    function typeLabel(e) {
        const k = kind(e);
        if (k === "folder")
            return "Folder";
        const m = { image: "Image", audio: "Audio", video: "Video", pdf: "PDF document", archive: "Archive" };
        if (m[k])
            return m[k];
        const x = ext(e.name);
        return x === "" ? "File" : x.toUpperCase() + " file";
    }
    function human(b) {
        if (b < 1024)
            return b + " B";
        const u = ["KB", "MB", "GB", "TB"];
        let i = -1;
        do {
            b /= 1024;
            i++;
        } while (b >= 1024 && i < 3);
        return b.toFixed(b < 10 ? 1 : 0) + " " + u[i];
    }
    function date(t) {
        const d = new Date(t * 1000);
        return d.toDateString() === new Date().toDateString() ? Qt.formatTime(d, "HH:mm") : Qt.formatDate(d, "d MMM yyyy");
    }
}
