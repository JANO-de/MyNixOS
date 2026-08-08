#!/usr/bin/env python3
import argparse
import re
import os
import json
from typing import Dict, List, Optional

parser = argparse.ArgumentParser(description='Niri KDL keybind reader')
parser.add_argument('--path', type=str, default="$HOME/.config/niri/config.kdl")
args = parser.parse_args()

KNOWN_MODS = {"mod", "shift", "ctrl", "alt", "super", "meta", "mod4", "mod3", "mod2", "mod5"}


class KeyBinding(dict):
    def __init__(self, mods, key, dispatcher, params, comment):
        self["mods"]       = mods
        self["key"]        = key
        self["dispatcher"] = dispatcher
        self["params"]     = params
        self["comment"]    = comment


class Section(dict):
    def __init__(self, children, keybinds, name):
        self["children"] = children
        self["keybinds"] = keybinds
        self["name"]     = name


def read_content(path: str) -> str:
    expanded = os.path.expanduser(os.path.expandvars(path))
    if not os.access(expanded, os.R_OK):
        return "error"
    with open(expanded, "r") as f:
        return f.read()


def parse_key_string(key_str: str):
    parts = [p.strip() for p in key_str.split("+")]
    mods, key = [], ""
    for p in parts:
        if p.lower() in KNOWN_MODS:
            mods.append(p)
        else:
            key = p
    return mods, key


def humanize_action(action: str) -> str:
    words = [w for w in re.split(r"[^a-zA-Z0-9%]+", action) if w]
    return " ".join(w[:1].upper() + w[1:] for w in words) or action


def generate_comment(action: str) -> str:
    action = action.strip()

    m = re.match(r'spawn\s+(.+)$', action)
    if m:
        parts = [p.strip().strip('"') for p in re.findall(r'"[^"]*"|\S+', m.group(1))]
        if not parts:
            return ""
        prog = parts[0]
        if prog in ("qs", "quickshell") and len(parts) >= 7 and parts[3] == "ipc" and parts[4] == "call":
            target, func = parts[5], parts[6]
            return f"Shell: {target} {func}"
        return f"Spawn: {os.path.basename(prog)}"

    m = re.match(r'spawn-sh\s+(.+)$', action)
    if m:
        cmd = m.group(1).strip().strip('"')
        return f"Run: {cmd[:60]}"

    # Internal niri action, e.g. close-window, focus-workspace 1, screenshot
    return humanize_action(action)


def split_actions(block: str) -> List[str]:
    actions = []
    for a in block.split(";"):
        a = a.strip()
        if a:
            actions.append(a)
    return actions


def main():
    content = read_content(args.path)
    if content == "error":
        result = Section([], [], "error")
        print(json.dumps(result))
        return

    lines = content.splitlines()

    # Find the top-level `binds { ... }` block(s).
    binds = []
    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        if re.match(r'^\s*binds\s*\{', line):
            depth = line.count("{") - line.count("}")
            block_lines = [line]
            i += 1
            while i < n and depth > 0:
                cur = lines[i]
                block_lines.append(cur)
                depth += cur.count("{") - cur.count("}")
                i += 1
            binds.append("\n".join(block_lines))
            continue
        i += 1

    keybinds = []
    for block in binds:
        # Iterate over lines inside the block, accumulating multiline binds.
        inner = block.split("\n")[1:-1]
        j = 0
        while j < len(inner):
            line = inner[j].strip()
            if not line or line.startswith("//"):
                j += 1
                continue

            # Accumulate until braces are balanced.
            buf = line
            while buf.count("{") - buf.count("}") != 0 and j + 1 < len(inner):
                j += 1
                buf += " " + inner[j].strip()

            m = re.match(r'^(\S+)\s*(.*?)\{\s*(.*?)\s*\}\s*$', buf, re.DOTALL)
            if not m:
                j += 1
                continue

            key_str = m.group(1)
            actions = split_actions(m.group(3))
            if not actions:
                j += 1
                continue

            comments = [c for c in (generate_comment(a) for a in actions) if c]
            if not comments:
                j += 1
                continue

            mods, key = parse_key_string(key_str)
            keybinds.append(KeyBinding(
                mods,
                key,
                actions[0].split(" ", 1)[0],
                "",
                "; ".join(comments),
            ))
            j += 1

    result = Section([], keybinds, "")
    print(json.dumps(result))


if __name__ == "__main__":
    main()
