#!/usr/bin/env python3
"""Convert MyNixOS from the custom module loader to the dendritic pattern
(flake-parts + import-tree). Run from the repo root, on a clean tree:

    python3 apply-dendritic.py && nix fmt && git add -A

What it does
  modules/<area>/<x>.nix  ->  parts/<area>/<x>.nix   (flake.nixosModules.<area>-<x>)
  modules/pkgs, */pkg     ->  pkgs/                   (plain callPackage files + overlay)
  tracker.py, flatpak,    ->  assets/                 (non-Nix files modules read)
  cursors
  hosts/<h>/default.nix   ->  parts/hosts/<h>.nix     (host flags + explicit module list)
  modules/default.nix     ->  parts/lib.nix           (mkHost + commonModules list)
  parts/hosts.nix, outputs.nix -> replaced by lib.nix, packages.nix, dev.nix
"""
import re
import shutil
import sys
from pathlib import Path

ROOT = Path.cwd()


def rd(p):
    return (ROOT / p).read_text()


def wr(p, s):
    f = ROOT / p
    f.parent.mkdir(parents=True, exist_ok=True)
    f.write_text(s)


def mv(a, b):
    dst = ROOT / b
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(ROOT / a), str(dst))


if (ROOT / "parts/lib.nix").exists() or not (ROOT / "modules/default.nix").exists():
    sys.exit("Looks already converted (or not the repo root). Aborting.")

NAMES = set()
REPORT = []


def split_header(text):
    lines = text.split("\n")
    i = 0
    while i < len(lines) and lines[i].startswith("#"):
        i += 1
    return "\n".join(lines[:i]), "\n".join(lines[i:]).strip("\n")


def wrap(name, text, repl=(), header=None, strip_imports=False):
    """Wrap one NixOS module file as a flake-parts module defining flake.nixosModules.<name>."""
    assert name not in NAMES, f"duplicate module name {name}"
    NAMES.add(name)
    for a, b in repl:
        assert a in text, (name, a)
        text = text.replace(a, b)
    if strip_imports:
        new = re.sub(r"\n\n  imports = \[\n.*?\n  \];\n", "\n", text, flags=re.S)
        assert new != text, (name, "imports block not found")
        text = new
    old_open, old_close = text.count("{"), text.count("}")
    hdr, body = split_header(text)
    if header is not None:
        hdr = header
    last = body.rstrip().split("\n")[-1]
    assert not last.lstrip().startswith("#"), (name, "ends in a comment")
    out = (hdr + "\n" if hdr else "") + "{ ... }:\n{\n  flake.nixosModules.%s = %s;\n}\n" % (
        name,
        body,
    )
    # sanity: the wrapper adds exactly two brace pairs
    # (header comments may contain braces, so compare against the full old text)
    assert out.count("{") == old_open + 2 and out.count("}") == old_close + 2, (name, "brace check")
    return out


def module(name, src, dst, **kw):
    wr(dst, wrap(name, rd(src), **kw))
    REPORT.append((name, dst))
    return name


# ---------------------------------------------------------------- features
common = []  # names every host gets, in the old loader's order


def add(name):
    common.append(name)


for f in ["boot", "nix", "users", "locale", "fonts", "shell", "home-manager"]:
    repl = [("modules/theme", "parts/theme")] if f == "home-manager" else ()
    add(module(f"core-{f}", f"modules/core/{f}.nix", f"parts/core/{f}.nix", repl=repl))

for f in ["compositor", "dotfiles", "session", "shell"]:
    add(module(f"desktop-{f}", f"modules/desktop/{f}.nix", f"parts/desktop/{f}.nix"))

for f in ["fullstack", "java"]:
    add(module(f"dev-{f}", f"modules/dev/{f}.nix", f"parts/dev/{f}.nix"))

add(
    module(
        "hardware",
        "modules/hardware/default.nix",
        "parts/hardware/default.nix",
        strip_imports=True,
        header="# Hardware switch: modules.hardware.enable. Off until a host sets it.\n"
        "# The features (bluetooth, firmware, nvidia, ...) are their own modules in this folder.",
    )
)
for f in ["bluetooth", "firmware", "drives", "nvidia", "cachyos", "openrgb"]:
    add(module(f"hardware-{f}", f"modules/hardware/{f}.nix", f"parts/hardware/{f}.nix"))

add(
    module(
        "programs",
        "modules/programs/default.nix",
        "parts/programs/default.nix",
        strip_imports=True,
        header="# Program sets: modules.programs.enable, .profile and .deskflow.*\n"
        "# Each program is its own module in this folder.",
    )
)
for f in ["lean", "full", "apps", "office", "files", "ai", "spotify", "deskflow"]:
    add(module(f"programs-{f}", f"modules/programs/{f}.nix", f"parts/programs/{f}.nix"))
# programs that carry their own package (the package lives in pkgs/<name>)
add(module("orchard", "modules/programs/orchard/default.nix", "parts/programs/orchard.nix"))
add(module("niXscout", "modules/programs/nixscout/default.nix", "parts/programs/nixscout.nix"))
add(module("nyaa-si", "modules/programs/nyaa-si/default.nix", "parts/programs/nyaa-si.nix"))
add(module("neo-mangal", "modules/programs/neo-mangal/default.nix", "parts/programs/neo-mangal.nix"))
add(module("vid-dl", "modules/programs/vid-dl/default.nix", "parts/programs/vid-dl.nix"))
for f in ["ytm-rs", "ytm-player", "ytui", "deviload"]:
    add(module(f"programs-{f}", f"modules/programs/{f}.nix", f"parts/programs/{f}.nix"))

# server/: five files have no enable switch, so they only go to the host that lists them.
SERVER_UNGATED = ["adguard", "music-autotag", "navidrome", "ntfy", "vikunja"]
server_order = [
    "adguard", "books", "caddy-lan", "caddy", "freshrss", "homepage", "it-tools", "jellyfin",
    "kavita", "media-stack", "media-tracker", "music-autotag", "navidrome", "ntfy", "open-webui",
    "openwa", "server", "stirling-pdf", "uptime-kuma", "vikunja",
]  # fmt: skip
for f in server_order:
    repl = ()
    if f == "media-tracker":
        repl = [("${./tracker.py}", "${../../assets/media-tracker/tracker.py}")]
    name = "server" if f == "server" else f"server-{f}"
    module(name, f"modules/server/{f}.nix", f"parts/server/{f}.nix", repl=repl)
    if f not in SERVER_UNGATED:
        add(name)

add(
    module(
        "services",
        "modules/services/default.nix",
        "parts/services/default.nix",
        strip_imports=True,
        header="# Services switch: modules.services.enable. Off until a host sets it.\n"
        "# The services (audio, networking, ssh, ...) are their own modules in this folder.",
    )
)
for f in ["networking", "audio", "printing", "ssh", "flatpak", "sunshine", "waydroid", "powertop", "smartd"]:
    add(module(f"services-{f}", f"modules/services/{f}.nix", f"parts/services/{f}.nix"))
add(
    module(
        "services-artcraft",
        "modules/services/artcraft/default.nix",
        "parts/services/artcraft.nix",
        repl=[
            (
                "./artcraft-launcher-0.13.0-linux-x86_64.flatpak",
                "../../assets/artcraft/artcraft-launcher-0.13.0-linux-x86_64.flatpak",
            )
        ],
    )
)
for f in ["virtualbox", "qmk", "tailscale"]:
    add(module(f"services-{f}", f"modules/services/{f}.nix", f"parts/services/{f}.nix"))

# host-only modules (not in `common`): listed by the host that wants them
module("services-ntfy-alerts", "modules/services/ntfy-alerts.nix", "parts/services/ntfy-alerts.nix")
module("services-wol", "modules/services/wol.nix", "parts/services/wol.nix")
module("services-backup", "modules/services/backup.nix", "parts/services/backup.nix")
module("services-scrub", "modules/services/scrub.nix", "parts/services/scrub.nix")
module("programs-music-dl", "modules/programs/music-dl.nix", "parts/programs/music-dl.nix")
module(
    "theme-stylix",
    "modules/theme/stylix.nix",
    "parts/theme/stylix.nix",
    repl=[("./n-cursor.nix", "../../pkgs/n-cursor.nix")],
)

# theme: the switch + the Home Manager base (gtk-qt.nix and home.nix folded in)
THEME = """\
# Theme: Home Manager config for user jano (GTK, Qt), switched by modules.theme.enable.
# palette (plain data) is parts/theme/_palette.nix: lib.nix passes it to every module as `theme`.
# GTK/Qt colours, fonts and cursor come from Stylix (theme-stylix); the Home Manager part below
# only keeps the account basics and the icon theme.
{ ... }:
{
  flake.nixosModules.theme =
    { config, lib, ... }:
    {
      options.modules.theme.enable = lib.mkEnableOption "Home Manager theming (GTK, Qt)";

      config = lib.mkIf config.modules.theme.enable {
        home-manager.users.jano =
          { pkgs, ... }:
          {
            home.username = "jano";
            home.homeDirectory = "/home/jano";
            home.stateVersion = "26.05";

            home.packages = [ pkgs.jq ];

            gtk = {
              enable = true;
              iconTheme = {
                name = "MacTahoe-dark";
                package = pkgs.callPackage ../../pkgs/mactahoe-icons.nix { };
              };
            };

            xdg.configFile."gtk-3.0/settings.ini".force = true;
            xdg.configFile."gtk-4.0/settings.ini".force = true;
          };
      };
    };
}
"""
# keep the original gtk-qt body honest: refuse to run if it changed since this script was written
gtk = rd("modules/theme/gtk-qt.nix")
for needle in ['name = "MacTahoe-dark";', 'home.stateVersion = "26.05";', "home.packages = [ pkgs.jq ];"]:
    assert needle in gtk, "gtk-qt.nix changed; update THEME in this script"
wr("parts/theme/default.nix", THEME)
NAMES.add("theme")
REPORT.append(("theme", "parts/theme/default.nix"))
add("theme")
add("gaming")  # parts/gaming.nix already is a flake-parts module

# ---------------------------------------------------------------- hosts
IMPORTS_RE = re.compile(r"\n  imports = \[\n.*?\n  \];\n", re.S)


def host(hostname, extras_before, extras_after):
    text = rd(f"hosts/{hostname}/default.nix")
    assert IMPORTS_RE.search(text), hostname
    text = IMPORTS_RE.sub("\n", text, count=1)
    body = wrap(f"host-{hostname}", text)
    # body is "{ ... }:\n{\n  flake.nixosModules.host-x = ...;\n}\n": add the nixosConfiguration inside
    assert body.endswith(";\n}\n")
    body = body[: -len("}\n")]
    lst = "\n".join(f'      "{n}"' for n in extras_before)
    hw = f"      ../../hosts/{hostname}/hardware-configuration.nix"
    tail = "".join(f' ++ [ "{n}" ]' for n in extras_after)
    body = body.replace("{ ... }:", "{ self, ... }:", 1)
    body += f"""
  flake.nixosConfigurations.{hostname} = self.lib.mkHost {{
    modules = [
      "host-{hostname}"
{lst}
{hw}
    ]
    ++ self.lib.commonModules{tail};
  }};
}}
"""
    wr(f"parts/{'hosts'}/{hostname}.nix", body)
    REPORT.append((f"host-{hostname}", f"parts/hosts/{hostname}.nix"))


host(
    "desktop",
    [
        "server-vikunja", "server-ntfy", "services-ntfy-alerts", "theme-stylix", "services-wol",
        "server-adguard", "programs-music-dl", "server-music-autotag", "services-backup",
        "services-scrub", "server-navidrome",
    ],  # fmt: skip
    [],
)
host("laptop", [], ["theme-stylix"])

# ---------------------------------------------------------------- lib.nix (mkHost + common list)
groups = []
cur = None
for n in common:
    grp = n.split("-")[0] if "-" in n and n not in ("nyaa-si", "neo-mangal", "vid-dl") else n
    grp = {"orchard": "programs", "niXscout": "programs", "nyaa-si": "programs", "neo-mangal": "programs",
           "vid-dl": "programs", "server": "server", "theme": "theme", "gaming": "gaming",
           "hardware": "hardware", "services": "services", "programs": "programs"}.get(grp, grp)  # fmt: skip
    if grp != cur:
        groups.append((grp, []))
        cur = grp
    groups[-1][1].append(n)
common_txt = ""
for g, names in groups:
    common_txt += f"    # {g}\n" + "".join(f'    "{n}"\n' for n in names)

LIB = (
    """\
# Shared helpers.
#   flake.lib.commonModules  every feature module that is switched by an option (or is plain
#                            config every host wants). A host gets all of them and turns the
#                            ones it needs on with modules.*; the order is the old loader's.
#   flake.lib.mkHost         the one place that builds a nixosSystem. Strings in `modules` are
#                            names under flake.nixosModules, anything else is passed through.
# Host-only modules (no enable switch, e.g. server-vikunja) are listed by the host itself.
{
  inputs,
  self,
  lib,
  ...
}:
let
  system = "x86_64-linux";
  theme = import ./theme/_palette.nix;

  commonModules = [
"""
    + common_txt
    + """\
  ];

  resolve = m: if builtins.isString m then self.nixosModules.${m} else m;
in
{
  flake.lib = {
    inherit commonModules;

    mkHost =
      { modules }:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs theme; };
        modules = [
          inputs.home-manager.nixosModules.home-manager
          inputs.forge.nixosModules.default
          inputs.niri-flake.nixosModules.niri
          inputs.mangowc.nixosModules.mango
          inputs.noctalia.nixosModules.default
          inputs.stylix.nixosModules.stylix
          inputs.nix-gaming.nixosModules.platformOptimizations
        ]
        ++ map resolve (lib.unique modules)
        ++ [
          {
            nixpkgs.overlays = [
              inputs.rust-overlay.overlays.default
              self.overlays.default
            ];
          }
        ];
      };
  };
}
"""
)
wr("parts/lib.nix", LIB)

# ---------------------------------------------------------------- packages + dev tooling
wr(
    "parts/packages.nix",
    """\
# Packages, apps and the overlay. The package definitions are plain callPackage files in ../pkgs.
{ inputs, ... }:
{
  flake.overlays.default = import ../pkgs/overlay.nix inputs;

  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs { inherit system; };
      # Orchard needs the Rust toolchain overlay (>= 1.96) and unfree allowed.
      rustPkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.rust-overlay.overlays.default ];
        config.allowUnfree = true;
      };

      orchard = rustPkgs.callPackage ../pkgs/orchard { };
      niXscout = pkgs.callPackage ../pkgs/nixscout { };
      nyaa-si = pkgs.callPackage ../pkgs/nyaa-si { src = inputs.nyaa-si-src; };
      neo-mangal = pkgs.callPackage ../pkgs/neo-mangal { src = inputs.neo-mangal-src; };
      vid-dl = pkgs.callPackage ../pkgs/vid-dl { };
      localsend-cli = pkgs.callPackage ../pkgs/localsend-cli { };
      matugen = pkgs.callPackage ../pkgs/matugen { };
    in
    {
      packages = {
        inherit
          orchard
          niXscout
          nyaa-si
          neo-mangal
          vid-dl
          localsend-cli
          matugen
          ;
      };

      apps = {
        orchard = {
          type = "app";
          program = "${orchard}/bin/orchard";
        };
        niXscout = {
          type = "app";
          program = "${niXscout}/bin/niXscout";
        };
        nyaa-si = {
          type = "app";
          program = "${nyaa-si}/bin/nyaa-si";
        };
        neo-mangal = {
          type = "app";
          program = "${neo-mangal}/bin/neo-mangal";
        };
      };
    };
}
""",
)
REPORT.append(("(packages/apps/overlay)", "parts/packages.nix"))

wr(
    "pkgs/overlay.nix",
    """\
# Overlay: our own packages, available as pkgs.<name> on every host.
inputs: final: _prev: {
  orchard = final.callPackage ./orchard { };
  niXscout = final.callPackage ./nixscout { };
  nyaa-si = final.callPackage ./nyaa-si { src = inputs.nyaa-si-src; };
  neo-mangal = final.callPackage ./neo-mangal { src = inputs.neo-mangal-src; };
  vid-dl = final.callPackage ./vid-dl { };
  localsend-cli = final.callPackage ./localsend-cli { };
  matugen = final.callPackage ./matugen { };
}
""",
)

wr(
    "parts/dev.nix",
    """\
# Dev tooling: treefmt (nix fmt), formatting check, pre-commit hook, dev shell.
{ inputs, self, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs { inherit system; };
      treefmt = inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
      };
      hooks = inputs.git-hooks.lib.${system}.run {
        src = self;
        hooks.treefmt = {
          enable = true;
          package = treefmt.config.build.wrapper;
        };
      };
    in
    {
      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.rustc
          pkgs.cargo
          pkgs.pkg-config
          pkgs.gtk4
          pkgs.libadwaita
          pkgs.glib
          pkgs.sqlite
          treefmt.config.build.wrapper
        ];
        inherit (hooks) shellHook;
      };
      formatter = treefmt.config.build.wrapper;
      checks = {
        formatting = treefmt.config.build.check self;
        pre-commit = hooks;
      };
    };
}
""",
)
REPORT.append(("(devShell/formatter/checks)", "parts/dev.nix"))

# ---------------------------------------------------------------- move non-module files
mv("modules/theme/palette.nix", "parts/theme/_palette.nix")
for pkg in ["orchard", "nyaa-si", "neo-mangal", "vid-dl"]:
    mv(f"modules/programs/{pkg}/pkg/default.nix", f"pkgs/{pkg}/default.nix")
for item in (ROOT / "modules/programs/nixscout/pkg").iterdir():
    mv(f"modules/programs/nixscout/pkg/{item.name}", f"pkgs/nixscout/{item.name}")
idx = rd("pkgs/nixscout/index.nix")
assert "../../../../flake.lock" in idx
wr("pkgs/nixscout/index.nix", idx.replace("../../../../flake.lock", "../../flake.lock"))
for d in ["localsend-cli", "matugen", "eq-sh"]:
    mv(f"modules/pkgs/{d}", f"pkgs/{d}")
mv("modules/theme/mactahoe-icons.nix", "pkgs/mactahoe-icons.nix")
nc = rd("modules/theme/n-cursor.nix")
assert "./cursors/N-Murder-Drones" in nc
wr("pkgs/n-cursor.nix", nc.replace("./cursors/N-Murder-Drones", "../assets/cursors/N-Murder-Drones"))
mv("modules/theme/cursors", "assets/cursors")
mv("modules/server/tracker.py", "assets/media-tracker/tracker.py")
mv(
    "modules/services/artcraft/artcraft-launcher-0.13.0-linux-x86_64.flatpak",
    "assets/artcraft/artcraft-launcher-0.13.0-linux-x86_64.flatpak",
)
mv("modules/server/README.txt", ".plan/notes/server-setup-readme.txt")

# ---------------------------------------------------------------- remove what was replaced
for p in [
    "parts/hosts.nix",
    "parts/outputs.nix",
    "hosts/desktop/default.nix",
    "hosts/laptop/default.nix",
]:
    (ROOT / p).unlink()

tracked_leftovers = []
for p in sorted((ROOT / "modules").rglob("*")):
    if p.is_file() and p.suffix == ".nix":
        p.unlink()  # every module was converted above (the loader and aggregators included)
for p in sorted((ROOT / "modules").rglob("*"), reverse=True):
    if p.is_dir() and not any(p.iterdir()):
        p.rmdir()
if (ROOT / "modules").exists():
    left = [str(p.relative_to(ROOT)) for p in (ROOT / "modules").rglob("*") if p.is_file()]
    if left:
        print("Left in modules/ (ignored files, delete by hand):", *left, sep="\n  ")
    else:
        shutil.rmtree(ROOT / "modules")

# ---------------------------------------------------------------- flake.nix, README, todo, drv-check
def patch(path, pairs):
    p = ROOT / path
    if not p.exists():
        print(f"skip {path}: not found")
        return
    s = p.read_text()
    for a, b in pairs:
        if a not in s:
            print(f"warning: {path}: text not found: {a[:50]!r}")
            continue
        s = s.replace(a, b, 1)
    p.write_text(s)


patch(
    "flake.nix",
    [
        (
            "# Flake entry point: inputs + thin outputs. Hosts are the folders in ./hosts; packages, apps and\n"
            "# the dev shell live in modules/pkgs.\n",
            "# Flake entry point: inputs + flake-parts. Every .nix file under ./parts is a flake-parts module\n"
            "# (loaded by import-tree): features, hosts, packages, dev tooling. Files or folders whose name\n"
            "# starts with _ are skipped by import-tree.\n",
        ),
        ("packaged in modules/programs/<name>/pkg ---", "packaged in pkgs/<name> ---"),
    ],
)

patch(
    "README.md",
    [
        (
            "flake.nix        inputs + thin outputs (hosts = the folders in hosts/)\n"
            "flake.lock       never edited by hand\n"
            "hosts/<host>/    switchboard (default.nix) + hardware + host-only files\n"
            "  dotfiles/      app-written configs kept in git (mango, ...)\n"
            "modules/         every capability, one module each\n",
            "flake.nix        inputs + flake-parts entry (import-tree ./parts)\n"
            "flake.lock       never edited by hand\n"
            "parts/           every flake-parts module (dendritic): one file per feature, host or output\n"
            "  hosts/         one file per host: its modules.* switches + its module list\n"
            "  lib.nix        mkHost and commonModules (the modules every host gets)\n"
            "hosts/<host>/    hardware-configuration.nix + dotfiles/ (app-written configs kept in git)\n"
            "pkgs/            package definitions (plain callPackage files) and the overlay\n"
            "assets/          non-Nix files that modules read (flatpak bundle, cursors, tracker.py)\n",
        ),
        (
            "flake.nix ──mkHost──▶ hosts/<host>/default.nix ──imports──▶ modules/default.nix (loader)\n"
            "                              │                                      │\n"
            "                      sets modules.* flags                walks modules/ and imports\n"
            "                                                          every module it finds\n",
            "flake.nix ──import-tree──▶ parts/**.nix  (each defines flake.nixosModules.<name>)\n"
            "                              │\n"
            "     parts/hosts/<host>.nix ──mkHost──▶ nixosConfigurations.<host>\n"
            "        sets modules.* flags, lists host-only modules, adds lib.commonModules\n",
        ),
        (
            "- `mkHost` (in `flake.nix`) adds Home Manager, the forge module and the overlays (`rust-overlay`, `self.overlays.default`).\n",
            "- `mkHost` (in `parts/lib.nix`) adds Home Manager, the forge module and the overlays (`rust-overlay`, `self.overlays.default`).\n",
        ),
        (
            "- **Loader** (`modules/default.nix`): a `*.nix` file is one module; a folder with its own `default.nix` is one unit (that file imports its children). Folders named `pkg`, `src`, `dotfiles`, `pkgs` hold packages and sources and are skipped.\n"
            "- A new host is just a new folder in `hosts/`; the flake picks it up.\n",
            "- **Dendritic**: every file under `parts/` is a flake-parts module found by `import-tree`; a feature is `flake.nixosModules.<area>-<name>`. Names starting with `_` are skipped.\n"
            "- `lib.commonModules` lists the option-gated modules every host gets; a host lists only its own extras (modules with no enable switch).\n"
            "- A new host is `parts/hosts/<name>.nix` (see desktop) plus `hosts/<name>/hardware-configuration.nix`.\n",
        ),
        (
            "1. Create `modules/<area>/<name>.nix` (or `<name>/default.nix`) with `options.modules.<area>.<name> = lib.mkEnableOption ...` and `config = lib.mkIf ...`.\n"
            "2. If the area has its own `default.nix`, add the file to its `imports`.\n"
            "3. Switch it on in `hosts/<host>/default.nix`.\n",
            "1. Create `parts/<area>/<name>.nix` defining `flake.nixosModules.<area>-<name>` with `options.modules.<area>.<name> = lib.mkEnableOption ...` and `config = lib.mkIf ...`.\n"
            "2. Add `\"<area>-<name>\"` to `commonModules` in `parts/lib.nix` (or to one host's list if it has no enable switch).\n"
            "3. Switch it on in `parts/hosts/<host>.nix`.\n",
        ),
        (
            "**Remove a module**: delete the file or folder (and its `imports` line), drop its flake input",
            "**Remove a module**: delete the file (and its name in `parts/lib.nix`), drop its flake input",
        ),
        (
            "**Add a host**: new folder `hosts/<name>/default.nix` that imports `../../modules` and sets its flags.",
            "**Add a host**: new `parts/hosts/<name>.nix` (copy desktop: a `host-<name>` module with the flags + `self.lib.mkHost`) and `hosts/<name>/hardware-configuration.nix`.",
        ),
    ],
)

patch(
    "todo.md",
    [
        ("- [x] Keep the custom module loader (no flake-parts)\n", "- [x] Dendritic layout: flake-parts + import-tree, parts/ (replaces the custom loader)\n"),
        ("- [x] Study fufexan (ported nh, registry pinning, store optimise)\n", "- [x] Study fufexan (ported nh, registry pinning, store optimise)\n- [ ] statix + deadnix in treefmt\n"),
    ],
)

patch(".plan/v2/drv-check.sh", [("for h in desktop laptop halos1; do", "for h in desktop laptop; do")])

print(f"\nConverted {len(REPORT)} modules/parts. Names: {len(NAMES)} (all unique).")
print("commonModules:", len(common))
print("Next: nix fmt && git add -A && nix flake check --no-build (or nh os build)")
