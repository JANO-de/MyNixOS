#!/usr/bin/env python3
"""Monitor Manager backend for niri.

Companion to iNiR's niri-config.py, focused on monitor layout work:

  outputs                 structured output list (modes, scale, transform, vrr)
  apply-output NAME k=v   temporary change through the niri IPC socket
  persist-output NAME k=v durable change in config.d/15-outputs.kdl
  persist-layout JSON     persist every connected output position at once
  profile save NAME       snapshot the live outputs as a named configuration
  profile list            list saved configurations
  profile load NAME       persist a saved configuration and reload niri
  profile delete NAME     forget a saved configuration
  profile current         print the live configuration

Unlike niri-config.py this script never falls back to editing the root
config.kdl. On NixOS that file is a read-only home-manager store symlink, so
persisting only works through the modular config.d section, which the
home-manager niri config includes as `include optional=true`.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

OUTPUTS_SECTION = "config.d/15-outputs.kdl"
MANAGED_HEADER = "// Managed by Monitor Manager\n"
VALIDATE_TIMEOUT = 10
RELOAD_SETTLE_SECONDS = 0.2

ALLOWED_PERSIST_KEYS = {"mode", "scale", "transform", "vrr", "position"}


# ─── Config locations ─────────────────────────────────────────────────


def get_niri_config_dir() -> Path:
    xdg = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    return Path(xdg) / "niri"


def get_outputs_file() -> Path:
    return get_niri_config_dir() / OUTPUTS_SECTION


def get_profiles_dir() -> Path:
    xdg = os.environ.get(
        "XDG_STATE_HOME", os.path.expanduser("~/.local/state")
    )
    return Path(xdg) / "quickshell" / "user" / "monitor-profiles"


# ─── niri IPC ─────────────────────────────────────────────────────────


def run_niri(*args) -> tuple[str, int]:
    try:
        r = subprocess.run(
            ["niri", "msg", *args], capture_output=True, text=True, timeout=5
        )
        return (r.stdout or r.stderr).strip(), r.returncode
    except Exception as exc:  # noqa: BLE001 - surfaced to the GUI as JSON
        return str(exc), 1


def reload_niri() -> tuple[str, int]:
    return run_niri("action", "load-config-file")


# ─── KDL helpers ──────────────────────────────────────────────────────


def _strip_kdl_line_comments(content: str) -> str:
    """Blank out `//` comments without touching `//` inside quoted strings."""
    out = []
    in_string = False
    i = 0
    length = len(content)
    while i < length:
        ch = content[i]
        if in_string:
            out.append(ch)
            if ch == "\\" and i + 1 < length:
                out.append(content[i + 1])
                i += 2
                continue
            if ch == '"':
                in_string = False
            i += 1
            continue
        if ch == '"':
            in_string = True
            out.append(ch)
            i += 1
            continue
        if ch == "/" and i + 1 < length and content[i + 1] == "/":
            while i < length and content[i] != "\n":
                out.append(" ")
                i += 1
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def _find_output_block_bounds(content: str, name: str):
    """Return (start, inner_start, inner_end, end) for `output "<name>" { ... }`."""
    pattern = re.compile(
        rf'(?m)^(?P<lead>[ \t]*)output\s+"{re.escape(name)}"\s*\{{(?P<inner>[^{{}}]*)\}}'
    )
    match = pattern.search(content)
    if not match:
        return None
    return match.start(), match.start("inner"), match.end("inner"), match.end()


def _iter_output_blocks(content: str):
    """Yield (name, block_body) for every top-level `output "<name>" { ... }`."""
    flattened = _strip_kdl_line_comments(content)
    pattern = re.compile(r'(?m)^[ \t]*output\s+"([^"]+)"\s*\{([^{}]*)\}')
    for match in pattern.finditer(flattened):
        yield match.group(1), match.group(2)


def _set_in_block(block_content: str, key: str, value: str) -> str:
    """Set `key value` inside a KDL block, preserving everything else.

    An existing line is replaced in place; a missing key is appended. The
    pattern is anchored to the line start so commented example lines are never
    rewritten.
    """
    escaped = re.escape(key)
    pattern = rf"(?m)^([ \t]*){escaped}\b[^\n]*"
    if re.search(pattern, block_content):
        if value:
            return re.sub(pattern, rf"\g<1>{key} {value}", block_content, count=1)
        return re.sub(pattern, rf"\g<1>{key}", block_content, count=1)
    indent = "    "
    if value:
        return block_content.rstrip() + f"\n{indent}{key} {value}\n"
    return block_content.rstrip() + f"\n{indent}{key}\n"


def _remove_from_block(block_content: str, key: str) -> str:
    return re.sub(rf"(?m)^[ \t]*{re.escape(key)}\b[^\n]*\n?", "", block_content)


def _upsert_output_block(content: str, name: str, changes: dict) -> str:
    """Apply key/value changes to one output block, creating it when absent."""
    bounds = _find_output_block_bounds(content, name)
    if bounds:
        _, inner_start, inner_end, _ = bounds
        block = content[inner_start:inner_end]
        for key, value in changes.items():
            if key == "mode":
                block = _set_in_block(block, "mode", f'"{value}"')
            elif key == "transform":
                block = _set_in_block(block, "transform", f'"{value}"')
            elif key == "scale":
                block = _set_in_block(block, "scale", value)
            elif key == "position":
                x, y = value
                block = _set_in_block(block, "position", f"x={x} y={y}")
            elif key == "vrr":
                if value == "off":
                    block = _remove_from_block(block, "variable-refresh-rate")
                elif value == "on-demand":
                    block = _set_in_block(
                        block, "variable-refresh-rate", "on-demand=true"
                    )
                else:
                    block = _set_in_block(block, "variable-refresh-rate", "")
        return content[:inner_start] + block + content[inner_end:]

    lines = []
    if "mode" in changes:
        lines.append(f'    mode "{changes["mode"]}"')
    if "transform" in changes:
        lines.append(f'    transform "{changes["transform"]}"')
    if "scale" in changes:
        lines.append(f"    scale {changes['scale']}")
    if "position" in changes:
        x, y = changes["position"]
        lines.append(f"    position x={x} y={y}")
    if "vrr" in changes:
        if changes["vrr"] == "on-demand":
            lines.append("    variable-refresh-rate on-demand=true")
        elif changes["vrr"] != "off":
            lines.append("    variable-refresh-rate")

    new_block = f'output "{name}" {{\n' + "\n".join(lines) + "\n}"
    if content.strip():
        return content.rstrip() + "\n\n" + new_block + "\n"
    return new_block + "\n"


def _render_profile_block(name: str, state: dict) -> str:
    """Render a full `output` block for a saved configuration."""
    lines = [f'output "{name}" {{']
    mode = state.get("mode")
    if mode:
        lines.append(f'    mode "{mode}"')
    scale = state.get("scale")
    if scale is not None:
        lines.append(f"    scale {scale}")
    transform = state.get("transform")
    if transform and transform != "Normal":
        lines.append(f'    transform "{transform}"')
    position = state.get("position")
    if position:
        lines.append(f"    position x={position['x']} y={position['y']}")
    vrr = state.get("vrr")
    if vrr == "on-demand":
        lines.append("    variable-refresh-rate on-demand=true")
    elif vrr == "on":
        lines.append("    variable-refresh-rate")
    lines.append("}")
    return "\n".join(lines) + "\n"


# ─── Validation & write ───────────────────────────────────────────────


def _validate_config() -> tuple[bool, str]:
    """Validate the composed config: section file + root config.kdl together."""
    root_config = get_niri_config_dir() / "config.kdl"
    outputs_file = get_outputs_file()

    if not root_config.exists():
        return False, f"Missing {root_config}"

    with tempfile.TemporaryDirectory() as tmp:
        shadow = Path(tmp) / "config.kdl"
        try:
            root_text = root_config.read_text()
        except OSError as exc:
            return False, f"Cannot read {root_config}: {exc}"

        # The section is included by the root config, so staging the include
        # tree already composes exactly what niri will load. Appending the
        # section as well would validate a file that differs from the live one,
        # hiding real breakage such as a key repeated inside one output block,
        # which niri does reject.
        if outputs_file.exists() and f'"{OUTPUTS_SECTION}"' not in root_text:
            return (
                False,
                f"{root_config} does not include \"{OUTPUTS_SECTION}\".\n"
                f"Add this line to the end of the file:\n"
                f"\n    include optional=true \"{OUTPUTS_SECTION}\"\n",
            )

        # Copy the include tree so the root config's relative includes resolve.
        for entry in get_niri_config_dir().iterdir():
            if entry.name == "config.kdl":
                continue
            target = shadow.parent / entry.name
            try:
                if entry.is_dir():
                    shutil.copytree(entry, target, dirs_exist_ok=True)
                else:
                    shutil.copy2(entry, target)
            except OSError as exc:
                return False, f"Cannot stage {entry}: {exc}"

        try:
            shadow.write_text(root_text)
        except OSError as exc:
            return False, f"Cannot write validation config: {exc}"

        try:
            r = subprocess.run(
                ["niri", "validate", "--config", str(shadow)],
                capture_output=True,
                text=True,
                timeout=VALIDATE_TIMEOUT,
            )
        except FileNotFoundError:
            return True, "niri not found; skipped validation"
        except subprocess.TimeoutExpired:
            return False, "niri validate timed out"

        if r.returncode != 0:
            return False, (r.stderr or r.stdout).strip()

    return True, (r.stdout or "").strip()


def _existing_or_header(path: Path) -> str:
    """Managed file content to build on, seeding the marker when absent."""
    return path.read_text() if path.exists() else MANAGED_HEADER


def _write_validated(path: Path, content: str) -> int:
    """Write the section file only if the composed config still validates."""
    previous = path.read_text() if path.exists() else None

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)

    valid, message = _validate_config()
    if not valid:
        if previous is not None:
            path.write_text(previous)
        else:
            path.unlink(missing_ok=True)
        print(json.dumps({"error": f"Config rejected by niri validate: {message}"}))
        return 1

    time.sleep(RELOAD_SETTLE_SECONDS)
    output, rc = reload_niri()
    if rc != 0:
        print(json.dumps({"error": f"niri reload failed: {output}"}))
        return 1

    print(json.dumps({"ok": True, "reload": output or "loaded"}))
    return 0


# ─── Commands: outputs ────────────────────────────────────────────────


def read_live_outputs() -> list:
    raw, rc = run_niri("-j", "outputs")
    if rc != 0:
        raise RuntimeError(f"niri msg failed: {raw}")

    data = json.loads(raw)
    configured_vrr = read_configured_vrr()
    result = []

    for name, out in data.items():
        modes = out.get("modes") or []
        # niri reports current_mode as null while an output is disabled. Keep
        # that distinct from a missing key: a disabled output has no current
        # mode at all, even though its available modes are still listed.
        current_idx = out.get("current_mode")
        logical = out.get("logical") or {}

        resolutions = {}
        resolution_order = []
        for i, m in enumerate(modes):
            key = f"{m['width']}x{m['height']}"
            rate = round(m["refresh_rate"] / 1000, 3)
            if key not in resolutions:
                resolutions[key] = {
                    "width": m["width"],
                    "height": m["height"],
                    "rates": [],
                    "preferred": bool(m.get("is_preferred", False)),
                }
                resolution_order.append(key)
            resolutions[key]["preferred"] = (
                resolutions[key]["preferred"] or bool(m.get("is_preferred", False))
            )
            if rate not in [r["rate"] for r in resolutions[key]["rates"]]:
                resolutions[key]["rates"].append(
                    {
                        "rate": rate,
                        "rate_string": f"{rate:.3f}",
                        "mode_index": i,
                        "preferred": bool(m.get("is_preferred", False)),
                    }
                )

        current_mode = (
            modes[current_idx]
            if isinstance(current_idx, int) and 0 <= current_idx < len(modes)
            else None
        )
        current_resolution = ""
        current_rate = None
        current_rate_string = ""
        if current_mode:
            current_resolution = f"{current_mode['width']}x{current_mode['height']}"
            current_rate = round(current_mode["refresh_rate"] / 1000, 3)
            current_rate_string = f"{current_rate:.3f}"

        physical = out.get("physical_size") or [0, 0]
        result.append(
            {
                "name": name,
                # An output can be connected but unmapped (turned off in the
                # config), in which case niri reports logical as null.
                "enabled": bool(logical),
                "make": out.get("make", ""),
                "model": out.get("model", ""),
                "serial": out.get("serial", ""),
                "physical_size": list(physical),
                "logical_size": [
                    int(logical.get("width", physical[0] or 0)),
                    int(logical.get("height", physical[1] or 0)),
                ],
                "current_resolution": current_resolution,
                "current_rate": current_rate,
                "current_rate_string": current_rate_string,
                "scale": logical.get("scale", 1.0),
                "transform": logical.get("transform", "Normal"),
                "position": {
                    "x": int(logical.get("x", 0)),
                    "y": int(logical.get("y", 0)),
                },
                "vrr_supported": bool(out.get("vrr_supported", False)),
                "vrr_enabled": bool(out.get("vrr_enabled", False)),
                "vrr_mode": configured_vrr.get(
                    name, "on" if out.get("vrr_enabled", False) else "off"
                ),
                "resolutions": [resolutions[k] for k in resolution_order],
            }
        )

    return result


def read_configured_vrr() -> dict:
    """VRR mode only lives in KDL: the IPC reports activity, not the mode."""
    outputs_file = get_outputs_file()
    if not outputs_file.exists():
        return {}

    try:
        content = outputs_file.read_text()
    except OSError:
        return {}

    modes = {}
    for name, block in _iter_output_blocks(content):
        match = re.search(r"^[ \t]*variable-refresh-rate([^\n]*)", block, re.MULTILINE)
        if not match:
            modes[name] = "off"
        elif "on-demand=true" in match.group(1):
            modes[name] = "on-demand"
        else:
            modes[name] = "on"
    return modes


def cmd_outputs(_args) -> int:
    try:
        print(json.dumps(read_live_outputs()))
    except Exception as exc:  # noqa: BLE001
        print(json.dumps({"error": str(exc)}))
        return 1
    return 0


# ─── Commands: apply / persist ────────────────────────────────────────


def cmd_apply_output(args) -> int:
    if len(args) < 2:
        print(json.dumps({"error": "Usage: apply-output <name> <key=value>..."}))
        return 1

    name = args[0]
    changes = {}
    for arg in args[1:]:
        if "=" not in arg or arg.startswith("="):
            print(json.dumps({"error": f"Invalid change argument: {arg}"}))
            return 1
        key, value = arg.split("=", 1)
        if key not in ALLOWED_PERSIST_KEYS:
            print(json.dumps({"error": f"Unknown output key: {key}"}))
            return 1
        changes[key] = value

    if "position" in changes:
        parts = changes["position"].split(",")
        if len(parts) != 2:
            print(json.dumps({"error": "position must be 'x,y'"}))
            return 1
        changes["position"] = (parts[0], parts[1])

    command = [name]
    for key, value in changes.items():
        if key == "position":
            command += ["position", "set", str(value[0]), str(value[1])]
        elif key == "vrr":
            # niri's IPC takes a boolean plus an --on-demand flag; there is no
            # three-valued argument, so on-demand has to expand to two args.
            if value in ("on", "on-demand"):
                command += ["vrr", "on"]
                if value == "on-demand":
                    command += ["--on-demand"]
            else:
                command += ["vrr", "off"]
        else:
            command += [key, str(value)]

    output, rc = run_niri("output", *command)
    if rc != 0:
        print(json.dumps({"error": output or "niri msg failed"}))
        return 1

    print(json.dumps({"ok": True}))
    return 0


def cmd_persist_output(args) -> int:
    if len(args) < 2:
        print(json.dumps({"error": "Usage: persist-output <name> <key=value>..."}))
        return 1

    name = args[0]
    changes = {}
    for arg in args[1:]:
        if "=" not in arg or arg.startswith("="):
            print(json.dumps({"error": f"Invalid change argument: {arg}"}))
            return 1
        key, value = arg.split("=", 1)
        if key not in ALLOWED_PERSIST_KEYS:
            print(json.dumps({"error": f"Unknown output key: {key}"}))
            return 1
        if key == "position":
            parts = value.split(",")
            if len(parts) != 2:
                print(json.dumps({"error": "position must be 'x,y'"}))
                return 1
            changes[key] = (parts[0], parts[1])
        else:
            changes[key] = value

    if not changes:
        print(json.dumps({"error": "No output changes provided."}))
        return 1

    outputs_file = get_outputs_file()
    outputs_file.parent.mkdir(parents=True, exist_ok=True)
    existing = _existing_or_header(outputs_file)
    return _write_validated(outputs_file, _upsert_output_block(existing, name, changes))


def cmd_persist_layout(args) -> int:
    """Persist every connected output position in one validated write.

    Niri re-runs automatic placement whenever the output configuration
    changes, so a durable layout has to make all connected positions explicit
    together rather than moving one monitor at a time.
    """
    if len(args) != 1:
        print(json.dumps({"error": "Usage: persist-layout <json-object>"}))
        return 1

    try:
        layout = json.loads(args[0])
    except json.JSONDecodeError as exc:
        print(json.dumps({"error": f"Invalid layout JSON: {exc}"}))
        return 1

    if not isinstance(layout, dict) or not layout:
        print(json.dumps({"error": "Layout must be a non-empty object."}))
        return 1

    normalized = {}
    for name, position in layout.items():
        try:
            normalized[name] = (int(position["x"]), int(position["y"]))
        except (KeyError, TypeError, ValueError):
            print(json.dumps({"error": f"Missing or invalid x/y for {name}."}))
            return 1

    outputs_file = get_outputs_file()
    outputs_file.parent.mkdir(parents=True, exist_ok=True)
    content = _existing_or_header(outputs_file)

    for name, (x, y) in normalized.items():
        content = _upsert_output_block(content, name, {"position": (x, y)})

    return _write_validated(outputs_file, content)


# ─── Commands: profiles ───────────────────────────────────────────────


def _slugify(name: str) -> str:
    slug = re.sub(r"[^a-zA-Z0-9._-]+", "-", name.strip().lower()).strip("-")
    return slug or "profile"


def _profile_path(name: str) -> Path:
    return get_profiles_dir() / f"{_slugify(name)}.json"


def _snapshot() -> dict:
    """Current live output state, reduced to what niri's config can express."""
    snapshot = {}
    for output in read_live_outputs():
        # A connected but unmapped output is deliberately left out. Capturing it
        # would give it a scale and a position, and loading that profile back
        # would switch the monitor on.
        if not output.get("enabled"):
            continue
        state = {
            "scale": output["scale"],
            "transform": output["transform"],
            "position": output["position"],
        }
        if output["current_resolution"]:
            state["mode"] = f"{output['current_resolution']}@{output['current_rate_string']}"
        if output["vrr_supported"]:
            state["vrr"] = output["vrr_mode"]
        snapshot[output["name"]] = state
    return snapshot


def cmd_profile(args) -> int:
    if not args:
        print(json.dumps({"error": "Usage: profile <save|list|load|delete|current> [name]"}))
        return 1

    action = args[0]

    if action == "current":
        try:
            print(json.dumps(_snapshot()))
        except Exception as exc:  # noqa: BLE001
            print(json.dumps({"error": str(exc)}))
            return 1
        return 0

    if action == "list":
        profiles = []
        directory = get_profiles_dir()
        if directory.exists():
            for path in sorted(directory.glob("*.json")):
                try:
                    data = json.loads(path.read_text())
                except (OSError, json.JSONDecodeError):
                    continue
                profiles.append(
                    {
                        "slug": path.stem,
                        "name": data.get("name", path.stem),
                        "created": data.get("created", 0),
                        "outputs": sorted(data.get("outputs", {}).keys()),
                    }
                )
        print(json.dumps(profiles))
        return 0

    if action in ("save", "load", "delete"):
        if len(args) < 2 or not args[1].strip():
            print(json.dumps({"error": f"profile {action} requires a name."}))
            return 1
        name = args[1].strip()
        path = _profile_path(name)

        if action == "save":
            try:
                outputs = _snapshot()
            except Exception as exc:  # noqa: BLE001
                print(json.dumps({"error": str(exc)}))
                return 1
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(
                json.dumps(
                    {"name": name, "created": int(time.time()), "outputs": outputs},
                    indent=2,
                )
                + "\n"
            )
            print(json.dumps({"ok": True, "slug": path.stem, "name": name}))
            return 0

        if action == "delete":
            if not path.exists():
                print(json.dumps({"error": f"No such profile: {name}"}))
                return 1
            path.unlink()
            print(json.dumps({"ok": True, "name": name}))
            return 0

        if not path.exists():
            print(json.dumps({"error": f"No such profile: {name}"}))
            return 1
        try:
            data = json.loads(path.read_text())
        except (OSError, json.JSONDecodeError) as exc:
            print(json.dumps({"error": f"Unreadable profile: {exc}"}))
            return 1

        outputs = data.get("outputs") or {}
        if not outputs:
            print(json.dumps({"error": "Profile has no outputs."}))
            return 1

        outputs_file = get_outputs_file()
        outputs_file.parent.mkdir(parents=True, exist_ok=True)

        # A profile describes a whole layout, so it replaces the managed
        # section outright. Upserting would leave blocks behind for outputs
        # that the profile does not mention, and niri would keep applying them
        # after the profile was "loaded".
        content = MANAGED_HEADER
        for output_name, state in outputs.items():
            content += _render_profile_block(output_name, state)

        rc = _write_validated(outputs_file, content)
        if rc == 0:
            _apply_to_live(outputs)
        return rc

    print(json.dumps({"error": f"Unknown profile action: {action}"}))
    return 1


def _apply_to_live(outputs: dict) -> None:
    """Mirror a loaded profile onto the running compositor immediately."""
    for name, state in outputs.items():
        command = [name]
        for key in ("mode", "scale", "transform"):
            if state.get(key) is not None:
                command += [key, str(state[key])]
        position = state.get("position")
        if position:
            command += ["position", "set", str(int(position["x"])), str(int(position["y"]))]
        if len(command) > 1:
            run_niri("output", *command)


def cmd_clear(_args) -> int:
    """Drop the managed section file so niri falls back to auto-placement.

    The section file is the only place output settings live, so this is the
    escape hatch: after it succeeds the config validates and reloads without
    any output overrides.
    """
    outputs_file = get_outputs_file()
    if not outputs_file.exists():
        print(json.dumps({"ok": True, "cleared": False}))
        return 0

    previous = outputs_file.read_text()
    outputs_file.unlink()

    valid, message = _validate_config()
    if not valid:
        outputs_file.write_text(previous)
        print(json.dumps({"error": f"Config rejected by niri validate: {message}"}))
        return 1

    time.sleep(RELOAD_SETTLE_SECONDS)
    output, rc = reload_niri()
    if rc != 0:
        print(json.dumps({"error": f"niri reload failed: {output}"}))
        return 1

    print(json.dumps({"ok": True, "cleared": True}))
    return 0


# ─── Entry point ──────────────────────────────────────────────────────


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    outputs = sub.add_parser("outputs")
    outputs.set_defaults(func=cmd_outputs)

    apply_output = sub.add_parser("apply-output")
    apply_output.add_argument("args", nargs="+")
    apply_output.set_defaults(func=cmd_apply_output)

    persist_output = sub.add_parser("persist-output")
    persist_output.add_argument("args", nargs="+")
    persist_output.set_defaults(func=cmd_persist_output)

    persist_layout = sub.add_parser("persist-layout")
    persist_layout.add_argument("args", nargs=1)
    persist_layout.set_defaults(func=cmd_persist_layout)

    profile = sub.add_parser("profile")
    profile.add_argument("args", nargs="+")
    profile.set_defaults(func=cmd_profile)

    clear = sub.add_parser("clear")
    clear.set_defaults(func=cmd_clear)

    parsed = parser.parse_args()
    try:
        return parsed.func(getattr(parsed, "args", []))
    except Exception as exc:  # noqa: BLE001 - never leak a traceback to QML
        print(json.dumps({"error": str(exc)}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
