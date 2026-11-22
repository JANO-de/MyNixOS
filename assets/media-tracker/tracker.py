#!/usr/bin/env python3
"""Scan the media library and register new content in an .xlsx tracker.

Metadata comes from the files (ffprobe tags, EPUB OPF, PDF info, ComicInfo.xml),
falling back to folder/file names. New titles are appended with Status=OnServer;
existing PendingDownload rows are flipped to OnServer. N/A rows are never touched.
"""
import json, os, re, subprocess, sys, tempfile, time, zipfile
import xml.etree.ElementTree as ET
from pathlib import Path
from openpyxl import Workbook, load_workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.worksheet.datavalidation import DataValidation
from openpyxl.formatting.rule import CellIsRule

MEDIA = Path(os.environ["MEDIA_DIR"])
XLSX = Path(os.environ["TRACKER_FILE"])
STATE = Path(os.environ["STATE_FILE"])
SETTLE = int(os.environ.get("SETTLE_SECONDS", "120"))
DIRS = {  # sheet key -> folder name
    "movies": os.environ.get("DIR_MOVIES", "Movies"),
    "shows": os.environ.get("DIR_SHOWS", "TV Shows"),
    "music": os.environ.get("DIR_MUSIC", "Music"),
    "books": os.environ.get("DIR_BOOKS", "Books"),
}
VIDEO = {".mkv", ".mp4", ".avi", ".m4v", ".mov", ".webm", ".ts", ".wmv"}
AUDIO = {".flac", ".mp3", ".m4a", ".ogg", ".opus", ".wav", ".aac", ".wma", ".alac"}
EBOOK = {".epub", ".pdf", ".mobi", ".azw3", ".fb2", ".djvu"}
COMIC = {".cbz", ".cbr", ".cb7"}
PARTIAL = (".part", ".!qb", ".tmp", ".crdownload", ".aria2", ".download")
NOW = time.time()

SHEETS = {
    "Manga & Books": ["Title", "Author", "Type", "Volumes/Chapters", "Status", "Notes"],
    "Movies": ["Title", "Year", "Quality", "Size (GB)", "Status", "Notes"],
    "Shows": ["Title", "Type", "Seasons", "Quality", "Status", "Notes"],
    "Music": ["Album", "Artist", "Year", "Tracks", "Status", "Notes"],
}


def log(*a):
    print(*a, flush=True)


def norm(s):
    return re.sub(r"[^a-z0-9]+", " ", str(s).lower()).strip()


def clean_name(name):
    name = re.sub(r"[\[\{][^\]\}]*[\]\}]", "", name)           # [tvdbid-1] {tmdb-2}
    name = re.sub(r"\(\s*(19|20)\d{2}\s*\)", "", name)        # (2026)
    name = re.sub(r"[._]+", " ", name)
    return re.sub(r"\s+", " ", name).strip(" -")


def year_from(s):
    m = re.search(r"(?<!\d)((?:19|20)\d{2})(?!\d)", str(s or ""))
    return int(m.group(1)) if m else None


def settled(p):
    return (NOW - p.stat().st_mtime) >= SETTLE and not p.name.lower().endswith(PARTIAL)


def files_under(root, exts):
    out = []
    for dp, _, fns in os.walk(root):
        for fn in fns:
            p = Path(dp) / fn
            if p.suffix.lower() in exts:
                out.append(p)
    return sorted(out)


def probe(path):
    try:
        r = subprocess.run(
            ["ffprobe", "-v", "quiet", "-print_format", "json", "-show_format", "-show_streams", str(path)],
            capture_output=True, text=True, timeout=60)
        return json.loads(r.stdout or "{}")
    except Exception as e:
        log("ffprobe failed:", path, e)
        return {}


def tags_of(info):
    t = {k.lower(): v for k, v in (info.get("format", {}).get("tags") or {}).items()}
    return t


def quality_of(info):
    for s in info.get("streams", []):
        if s.get("codec_type") == "video" and s.get("disposition", {}).get("attached_pic") != 1:
            h = int(s.get("height") or 0)
            if h >= 2000: return "4K"
            if h >= 1000: return "1080p"
            if h >= 700: return "720p"
            if h > 0: return "480p"
    return ""


def has_japanese_audio(info):
    for s in info.get("streams", []):
        if s.get("codec_type") == "audio" and (s.get("tags") or {}).get("language", "").lower() in ("jpn", "ja"):
            return True
    return False


def size_gb(paths):
    return round(sum(p.stat().st_size for p in paths) / 1024 ** 3, 2)


def sig(paths):
    return f"{len(paths)}:{max((p.stat().st_mtime for p in paths), default=0):.0f}:{sum(p.stat().st_size for p in paths)}"


# ---------- collectors: each returns list of (sheet, key, row_dict, signature) ----------

def collect_movies(root):
    out = []
    for entry in sorted(root.iterdir()):
        vids = [entry] if entry.is_file() and entry.suffix.lower() in VIDEO else (
            files_under(entry, VIDEO) if entry.is_dir() else [])
        if not vids: continue
        if not all(settled(v) for v in vids): continue
        main = max(vids, key=lambda p: p.stat().st_size)
        info = probe(main)
        t = tags_of(info)
        base = clean_name(entry.stem if entry.is_file() else entry.name)
        title = (t.get("title") or "").strip() or base
        if norm(title) != norm(base) and year_from(title) is None and len(title) < 3:
            title = base
        year = year_from(entry.name) or year_from(t.get("date") or t.get("year") or t.get("creation_time"))
        out.append(("Movies", f"{norm(base)}|{year or ''}",
                    {"Title": title, "Year": year, "Quality": quality_of(info), "Size (GB)": size_gb(vids)},
                    sig(vids)))
    return out


def collect_shows(root):
    out = []
    for show in sorted(p for p in root.iterdir() if p.is_dir()):
        eps = files_under(show, VIDEO)
        if not eps or not all(settled(e) for e in eps): continue
        seasons = set()
        for e in eps:
            m = re.search(r"[Ss](\d{1,2})[ ._-]*[Ee]\d", e.name) or re.search(r"[Ss]eason[ ._-]*(\d{1,2})", str(e.parent.name))
            if m: seasons.add(int(m.group(1)))
        if seasons:
            lo, hi = min(seasons), max(seasons)
            sstr = f"S{lo}" if lo == hi else f"S{lo}-S{hi}"
        else:
            sstr = ""
        info = probe(eps[0])
        t = tags_of(info)
        title = (t.get("show") or "").strip() or clean_name(show.name)
        typ = "Anime" if has_japanese_audio(info) else "Show"
        out.append(("Shows", norm(clean_name(show.name)),
                    {"Title": title, "Type": typ, "Seasons": sstr, "Quality": quality_of(info)},
                    sig(eps)))
    return out


def collect_music(root):
    out = []
    albums = {}
    for f in files_under(root, AUDIO):
        albums.setdefault(f.parent, []).append(f)
    for folder, tracks in sorted(albums.items()):
        if not all(settled(t) for t in tracks): continue
        t = tags_of(probe(tracks[0]))
        album = (t.get("album") or "").strip() or clean_name(folder.name)
        artist = (t.get("album_artist") or t.get("albumartist") or t.get("artist") or "").strip()
        if not artist:
            rel = folder.relative_to(root).parts
            artist = rel[0] if len(rel) > 1 else ""
        year = year_from(t.get("date") or t.get("year") or t.get("originaldate"))
        out.append(("Music", f"{norm(album)}|{norm(artist)}",
                    {"Album": album, "Artist": artist, "Year": year, "Tracks": len(tracks)},
                    sig(tracks)))
    return out


def epub_meta(path):
    try:
        with zipfile.ZipFile(path) as z:
            cont = ET.fromstring(z.read("META-INF/container.xml"))
            opf_path = cont.find(".//{*}rootfile").attrib["full-path"]
            opf = ET.fromstring(z.read(opf_path))
            title = opf.findtext(".//{*}title")
            author = opf.findtext(".//{*}creator")
            return (title or "").strip(), (author or "").strip()
    except Exception:
        return "", ""


def pdf_meta(path):
    try:
        r = subprocess.run(["pdfinfo", str(path)], capture_output=True, text=True, timeout=30)
        d = dict(l.split(":", 1) for l in r.stdout.splitlines() if ":" in l)
        return d.get("Title", "").strip(), d.get("Author", "").strip()
    except Exception:
        return "", ""


def comicinfo(path):
    try:
        with zipfile.ZipFile(path) as z:
            name = next((n for n in z.namelist() if n.lower().endswith("comicinfo.xml")), None)
            if not name: return "", ""
            x = ET.fromstring(z.read(name))
            return (x.findtext("Series") or "").strip(), (x.findtext("Writer") or "").strip()
    except Exception:
        return "", ""


def book_meta(f):
    ext = f.suffix.lower()
    if ext == ".epub": return epub_meta(f)
    if ext == ".pdf": return pdf_meta(f)
    return "", ""


def collect_books(root):
    out = []
    for entry in sorted(root.iterdir()):
        if entry.is_file():
            files = [entry]
        else:
            files = files_under(entry, EBOOK | COMIC)
        if not files or not all(settled(f) for f in files): continue
        comics = [f for f in files if f.suffix.lower() in COMIC]
        is_manga = bool(comics) and len(comics) >= len(files) / 2
        if entry.is_dir() and (len(files) > 1 or is_manga):      # series folder -> one row
            title, author = clean_name(entry.name), ""
            if comics:
                s, w = comicinfo(comics[0])
                title, author = s or title, w
            else:
                _, author = book_meta(files[0])
            out.append(("Manga & Books", norm(title),
                        {"Title": title, "Author": author, "Type": "Manga" if is_manga else "Book",
                         "Volumes/Chapters": f"{len(files)} files"},
                        sig(files)))
        else:                                                    # single book
            f = files[0]
            t, a = book_meta(f)
            base = clean_name(f.stem)
            if f.suffix.lower() in COMIC:
                s, w = comicinfo(f)
                t, a = s or t, w or a
            out.append(("Manga & Books", norm(t or base),
                        {"Title": t or base, "Author": a,
                         "Type": "Manga" if f.suffix.lower() in COMIC else "Book",
                         "Volumes/Chapters": ""},
                        sig(files)))
    return out


# ---------- workbook ----------

def new_workbook():
    wb = Workbook(); wb.remove(wb.active)
    for name, hdr in SHEETS.items():
        ws = wb.create_sheet(name)
        for c, h in enumerate(hdr, 1):
            x = ws.cell(1, c, h)
            x.font = Font(name="Arial", bold=True, color="FFFFFF")
            x.fill = PatternFill("solid", fgColor="1F2937")
            x.alignment = Alignment(horizontal="center")
        for i, w in enumerate([34, 24, 14, 18, 18, 36], 1):
            ws.column_dimensions[chr(64 + i)].width = w
        ws.freeze_panes = "A2"
        ws.auto_filter.ref = "A1:F501"
    return wb


def ensure_status_ui(ws):
    if not ws.data_validations.dataValidation:
        dv = DataValidation(type="list", formula1='"OnServer,PendingDownload,N/A"', allow_blank=True)
        ws.add_data_validation(dv); dv.add("E2:E501")
    if not ws.conditional_formatting:
        for v, col in (("OnServer", "C6EFCE"), ("PendingDownload", "FFEB9C"), ("N/A", "D9D9D9")):
            ws.conditional_formatting.add("E2:E501", CellIsRule(
                operator="equal", formula=[f'"{v}"'], fill=PatternFill("solid", bgColor=col, fgColor=col)))


def register(wb, items, state):
    added = updated = 0
    index = {}
    for sheet in SHEETS:
        if sheet not in wb.sheetnames:
            ws = wb.create_sheet(sheet)
            for c, h in enumerate(SHEETS[sheet], 1):
                ws.cell(1, c, h).font = Font(name="Arial", bold=True)
        ws = wb[sheet]
        ensure_status_ui(ws)
        hdr = {str(c.value): c.column for c in ws[1] if c.value}
        index[sheet] = (ws, hdr, {})
        for r in range(2, ws.max_row + 1):
            t = ws.cell(r, 1).value
            if t and not str(t).startswith("Example:"):
                key = norm(t)
                if sheet == "Movies": key += "|" + str(ws.cell(r, hdr.get("Year", 2)).value or "")
                if sheet == "Music": key += "|" + norm(ws.cell(r, hdr.get("Artist", 2)).value or "")
                index[sheet][2][key] = r
    for sheet, key, row, sg in items:
        if state.get(f"{sheet}|{key}") == sg:
            continue
        ws, hdr, rows = index[sheet]
        scol = hdr["Status"]
        # lookup: also match movies without year / music without artist loosely
        r = rows.get(key) or rows.get(key.split("|")[0] + "|") if sheet in ("Movies", "Music") else rows.get(key)
        if r:
            cur = ws.cell(r, scol).value
            if cur in (None, "", "PendingDownload"):
                ws.cell(r, scol, "OnServer"); updated += 1
                log("updated ->", sheet, row[SHEETS[sheet][0]])
            for k, v in row.items():                       # fill blanks only
                c = hdr.get(k)
                if c and ws.cell(r, c).value in (None, "") and v not in (None, ""):
                    ws.cell(r, c, v)
        else:
            r = 2
            while ws.cell(r, 1).value not in (None, "") and not str(ws.cell(r, 1).value).startswith("Example:"):
                r += 1
            for k, v in row.items():
                if k in hdr: ws.cell(r, hdr[k], v)
            ws.cell(r, scol, "OnServer")
            ws.cell(r, hdr["Notes"], "auto-added " + time.strftime("%Y-%m-%d")) if "Notes" in hdr else None
            for c in range(1, ws.max_column + 1):
                cell = ws.cell(r, c); cell.font = Font(name="Arial"); cell.alignment = Alignment(horizontal="left")
            rows[key] = r; added += 1
            log("added   ->", sheet, row[SHEETS[sheet][0]])
        state[f"{sheet}|{key}"] = sg
    return added, updated


def main():
    state = json.loads(STATE.read_text()) if STATE.exists() else {}
    items = []
    for key, fn in (("movies", collect_movies), ("shows", collect_shows),
                    ("music", collect_music), ("books", collect_books)):
        root = MEDIA / DIRS[key]
        if root.is_dir():
            items += fn(root)
        else:
            log("skip, missing:", root)
    wb = load_workbook(XLSX) if XLSX.exists() else new_workbook()
    added, updated = register(wb, items, state)
    if added or updated or not XLSX.exists():
        XLSX.parent.mkdir(parents=True, exist_ok=True)
        fd, tmp = tempfile.mkstemp(dir=XLSX.parent, suffix=".xlsx"); os.close(fd)
        wb.save(tmp); os.replace(tmp, XLSX)
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps(state))
    log(f"done: {added} added, {updated} updated, {len(items)} entries scanned")


if __name__ == "__main__":
    sys.exit(main())
