#!/usr/bin/env python3
"""suite-lint: static checks for the Halo app suite QML (no QML runtime needed).

Usage:  python3 scripts/suite-lint.py [apps_dir]      (default: shell/halo/apps)
Checks: bracket balance, icon names exist in common/Ic.qml, every element type is known,
        qs.common / qs.suite imports present, duplicate ids, anchors on Row/Column/Grid/Flow children,
        `anchors { ... };`, method names starting with an uppercase letter.
Exit code 1 when something is wrong.
"""
import re
import sys
from pathlib import Path

root = Path(sys.argv[1] if len(sys.argv) > 1 else "shell/halo/apps")

BUILTIN = set("""Item Rectangle Text Column Row Grid Flow Repeater ListView GridView Flickable MouseArea TextInput TextEdit Timer
Behavior NumberAnimation ColorAnimation Image Component Connections Shape ShapePath PathAngleArc PathSvg MultiEffect
ShellRoot FloatingWindow PanelWindow Process StdioCollector SplitParser SystemClock FileView Scope Variants Singleton
DragHandler PointHandler TapHandler WheelHandler Loader FontLoader JsonObject JsonAdapter ScrollBar Gradient GradientStop
SequentialAnimation ParallelAnimation PropertyAnimation Translate Scale Rotation Item Window""".split())

local = {p.stem for d in ("common", "suite") for p in (root / d).glob("*.qml")}
ic_src = (root / "common" / "Ic.qml").read_text()
icons = set(re.findall(r'^\s{8}(\w+):\s*"', ic_src, re.M))

problems = []


def strip(src):
    """Blank out strings and comments, keep length and newlines."""
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if c == "/" and src[i:i + 2] == "//":
            j = src.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
        elif c == "/" and src[i:i + 2] == "/*":
            j = src.find("*/", i)
            j = n if j < 0 else j + 2
            out.append(re.sub(r"[^\n]", " ", src[i:j]))
            i = j
        elif c in "\"'":
            j = i + 1
            while j < n and src[j] != c:
                j += 2 if src[j] == "\\" else 1
            out.append(c + " " * (j - i - 1) + c)
            i = j + 1
        else:
            out.append(c)
            i += 1
    return "".join(out)


def check(path):
    raw = path.read_text()
    src = strip(raw)
    rel = path.relative_to(root)
    is_suite = rel.parts[0] == "suite"
    is_common = rel.parts[0] == "common"

    def bad(line, msg):
        problems.append(f"{rel}:{line}: {msg}")

    # brackets
    pairs = {")": "(", "]": "[", "}": "{"}
    st = []
    for ln, line in enumerate(src.split("\n"), 1):
        for ch in line:
            if ch in "([{":
                st.append((ch, ln))
            elif ch in ")]}":
                if not st or st[-1][0] != pairs[ch]:
                    bad(ln, f"unbalanced '{ch}'")
                    st = []
                    break
                st.pop()
    for ch, ln in st:
        bad(ln, f"unclosed '{ch}'")

    # imports
    imports = set(re.findall(r"^import\s+(\S+)", raw, re.M))
    body_names = set(re.findall(r"\b([A-Z]\w*)\s*\{", src))
    uses_common = bool(re.search(r"\b(AppTheme|Ico|Pill|MenuPop|RoundImg|AppWindow)\b", src))
    uses_suite = body_names & {p for p in local if (root / "suite" / (p + ".qml")).exists()}
    if uses_common and not is_common and "qs.common" not in imports:
        bad(1, "uses qs.common types but does not import qs.common")
    if uses_suite and not is_suite and "qs.suite" not in imports:
        bad(1, f"uses {sorted(uses_suite)} but does not import qs.suite")

    # element types
    for m in re.finditer(r"(?<![\w.])([A-Z]\w*)\s*\{", src):
        name = m.group(1)
        line = src.count("\n", 0, m.start()) + 1
        if name not in BUILTIN and name not in local:
            bad(line, f"unknown element type '{name}'")

    # icon names
    for ln, line in enumerate(raw.split("\n"), 1):
        code = line.split("//")[0]
        if re.search(r"\b(icon|ico)\s*:|Ico\s*\{|return\s+\"", code) or "condIcon" in code:
            for t in re.findall(r'"([a-z]+)"', code):
                if re.search(r"\bicon\b|\bico\b|Ico\s*\{|return", code) and t not in icons:
                    if re.search(r'(placeholder|text|title|label|subtitle)\s*:\s*"' + t, code):
                        continue
                    bad(ln, f"icon '{t}' not in Ic.qml")

    # duplicate ids
    seen = {}
    for m in re.finditer(r"\bid\s*:\s*(\w+)", src):
        line = src.count("\n", 0, m.start()) + 1
        if m.group(1) in seen:
            bad(line, f"duplicate id '{m.group(1)}' (first at line {seen[m.group(1)]})")
        seen[m.group(1)] = line

    # misc gotchas from HANDOFF section 0
    for m in re.finditer(r"anchors\s*\{[^}]*\}\s*;", src):
        bad(src.count("\n", 0, m.start()) + 1, "`anchors { ... };` is illegal")
    for m in re.finditer(r"\bfunction\s+([A-Z]\w*)\s*\(", src):
        bad(src.count("\n", 0, m.start()) + 1, f"method name '{m.group(1)}' starts with uppercase")

    # anchors on children of positioners
    stack = []   # (name, line)
    pos = 0
    for m in re.finditer(r"\{|\}|anchors\.\w+", src):
        tok = m.group(0)
        line = src.count("\n", 0, m.start()) + 1
        if tok == "{":
            before = src[:m.start()].rstrip()
            em = re.search(r"([A-Z]\w*)$", before)
            bm = re.search(r"Behavior\s+on\s+\w+$", before)
            if bm:
                stack.append(("Behavior", line))
            elif em and not re.search(r"(property|alias)\s+\w+$", before):
                stack.append((em.group(1), line))
            elif re.search(r"anchors$", before):
                stack.append(("anchorsGroup", line))
            else:
                stack.append(("js", line))
        elif tok == "}":
            if stack:
                stack.pop()
        else:
            els = [s for s in stack if s[0] not in ("js", "Behavior")]
            if not els:
                continue
            cur = els[-1][0]
            idx = len(els) - 2
            parent = els[idx][0] if idx >= 0 else None
            if parent == "Repeater" and idx - 1 >= 0:
                parent = els[idx - 1][0]
            if cur == "anchorsGroup" and idx >= 0:
                continue
            if parent in ("Row", "Column", "Grid", "Flow") and cur not in ("Repeater",):
                bad(line, f"{tok} on a child of {parent} ({cur})")


files = sorted(root.rglob("*.qml"))
scope = [p for p in files if p.relative_to(root).parts[0] not in ("files", "gallery") and p.name not in ("files.qml", "gallery.qml")]
for p in scope:
    check(p)

print(f"checked {len(scope)} files, {len(icons)} icons known, {len(local)} local components")
for p in problems:
    print("  " + p)
print("OK" if not problems else f"{len(problems)} problem(s)")
sys.exit(1 if problems else 0)
