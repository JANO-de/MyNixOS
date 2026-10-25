#!/usr/bin/env python3
"""halo-recolor-icons DARK MID LIGHT OUTDIR NAME...

Recolours the Arcticons (line art, $HALO_ARCTIC_SRC = icons/white dir) or, failing that, the
Papirus SVG of each icon NAME into a 3-stop ramp (by luminance) built from the palette colours. Writes OUTDIR/NAME.svg, prints a JSON list of the names written, and deletes
sibling dirs of OUTDIR (old palettes). Source: $HALO_ICON_SRC (dir holding Papirus/).
"""
import glob
import json
import os
import re
import shutil
import sys

if len(sys.argv) < 5:
    sys.exit("usage: halo-recolor-icons DARK MID LIGHT OUTDIR NAME...")


def parse_hex(h):
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


STOPS = [parse_hex(a) for a in sys.argv[1:4]]
OUT = sys.argv[4].rstrip("/")
NAMES = sys.argv[5:]
SRC = os.environ.get("HALO_ICON_SRC", "")
ARC = os.environ.get("HALO_ARCTIC_SRC", "")

SKIP = {"org", "com", "io", "net", "de", "app", "desktop", "gnome", "kde", "gtk", "qt", "github", "flatpak", "linux", "gui", "client"}
# Linux app / generic icon names -> Arcticons file names (first that exists wins).
ALIAS = {
    "terminal": ["alacritty", "kitty", "foot", "konsole", "xterm", "wezterm", "gnome_terminal", "utilities_terminal", "org_gnome_console"],
    "folder": ["nautilus", "thunar", "dolphin", "pcmanfm", "nemo", "files", "system_file_manager", "org_gnome_nautilus"],
    "document_viewer": ["zathura", "evince", "okular", "pdf_viewer", "mupdf", "atril"],
    "volume": ["pavucontrol", "pulseaudio", "pipewire", "helvum", "easyeffects"],
    "settings": ["applications_system", "systemsettings", "gnome_control_center", "system_settings", "gnome_tweaks"],
    "browser": ["angelfish", "epiphany", "falkon", "qutebrowser", "librewolf"],
    "calculator": ["gnome_calculator", "kcalc", "qalculate"],
    "notes": ["gnome_text_editor", "kate", "gedit", "mousepad", "xed"],
    "clock": ["gnome_clocks", "kclock"],
    "gallery": ["shotwell", "gwenview", "loupe", "eog"],
    "camera": ["cheese", "snapshot"],
    "music": ["rhythmbox", "lollypop", "amarok", "elisa"],
    "calendar_1": ["gnome_calendar", "korganizer"],
    "contacts": ["gnome_contacts", "kaddressbook"],
    "top": ["btop", "htop", "btop_", "bpytop", "bottom", "resources", "mission_center"],
    "print": ["printer", "system_config_printer", "cups", "printers"],
    "share_to_computer": ["deskflow", "barrier", "synergy", "input_leap", "lan_mouse"],
    "sketch": ["infinipaint", "infini_paint"],
    "services": ["uuctl", "systemd", "systemctl", "systemd_manager"],
    "book": ["nixos_manual", "nixos", "nix", "nix_manual", "manual", "nixos_help"],
    "mail": ["geary", "evolution", "kmail"],
}
ALIAS_REV = {a: t for t, lst in ALIAS.items() for a in lst}


def ramp(r, g, b):
    lv = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
    if lv <= 0.45:
        t, lo, hi = lv / 0.45, STOPS[0], STOPS[1]
    else:
        t, lo, hi = (lv - 0.45) / 0.55, STOPS[1], STOPS[2]
    return "#%02x%02x%02x" % tuple(round(lo[i] + (hi[i] - lo[i]) * t) for i in range(3))


# Only colour properties are touched (never ids / hrefs / url(#...)).
PROP = r"((?:fill|stroke|stop-color|flood-color|lighting-color|color)\s*[:=]\s*[\"']?)"
HEX = re.compile(PROP + r"#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})(?![0-9a-zA-Z])")
RGB = re.compile(PROP + r"rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)")
NAMED = re.compile(PROP + r"(white|black)(?![\w-])")


def recolor(text):
    text = HEX.sub(lambda m: m.group(1) + ramp(*parse_hex(m.group(2))), text)
    text = RGB.sub(lambda m: m.group(1) + ramp(int(m.group(2)), int(m.group(3)), int(m.group(4))), text)
    text = NAMED.sub(lambda m: m.group(1) + ramp(*((255,) * 3 if m.group(2) == "white" else (0,) * 3)), text)
    return text


def find_svg(name):
    best, best_size = None, -1
    for theme in ("Papirus", "Papirus-Dark"):
        for p in glob.glob("%s/%s/*/apps/%s.svg" % (SRC, theme, name)):
            head = os.path.basename(os.path.dirname(os.path.dirname(p)))
            size = int(head.split("x")[0]) if head[:1].isdigit() else 0
            if size > best_size:
                best, best_size = p, size
    return best


def find_arctic(name):
    if not ARC:
        return None
    base = name.lower().replace("-", "_")
    cands = [base, base.replace(".", "_")]
    toks = [t for t in re.split(r"[._]", base) if t and t not in SKIP]
    cands += ["_".join(toks)] + sorted(toks, key=len, reverse=True)
    cands += [ALIAS_REV[c] for c in list(cands) if c in ALIAS_REV]
    for c in cands:
        p = os.path.join(ARC, c + ".svg")
        if os.path.isfile(p):
            return p
    return None


def main():
    parent = os.path.dirname(OUT)
    if os.path.isdir(parent):
        for d in os.listdir(parent):
            if os.path.join(parent, d) != OUT:
                shutil.rmtree(os.path.join(parent, d), ignore_errors=True)
    os.makedirs(OUT, exist_ok=True)
    done = []
    for name in sorted(set(NAMES)):
        if not name or "/" in name or name.startswith("."):
            continue
        src = find_arctic(name)
        line_art = src is not None
        if not src:
            src = find_svg(name)
        if not src:
            continue
        try:
            with open(src, encoding="utf-8") as fh:
                text = fh.read()
            if line_art and "stroke-width" not in text:
                text = text.replace("stroke-linecap", "stroke-width:1.5;stroke-linecap", 1)
            with open(os.path.join(OUT, name + ".svg"), "w", encoding="utf-8") as fh:
                fh.write(recolor(text))
            done.append(name)
        except (OSError, UnicodeDecodeError):
            pass
    print(json.dumps(done))


main()
