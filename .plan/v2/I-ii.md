# M4: ii-p3drovfx on Hyprland (desktop and laptop)

Upstream: `github.com/P3DROVFX/ii-p3drovfx` (GPL-3.0, fork of ii-vynx / illogical-impulse; Quickshell config `dots/.config/quickshell/ii`). **Scope: `desktop` and `laptop` only. `halos1` must stay byte-identical** (rule 15: its drvPath never changes in this milestone). Owner decision (2026-10-27): **Hyprland replaces mangoWM** on these two hosts; no mango backend is built. Run after R-4 so files land in the final layout.

## What the director verified (upstream wiki/README, 2026-10-27)
- No flake, no Nix package. `setup-ii-p3drovfx.sh` is a bash installer that writes into `$HOME`; its "Nix" support is not declarative NixOS. **Never run it.**
- Needs Hyprland **0.56.1+** (Lua config), Matugen **4.1.0+**, quickshell **0.3.0+**.
- Uses Hyprland IPC, Hyprland global shortcuts, and Hyprland's built-in scrolling layout (`general.layout = "scrolling"`, Hyprland wiki) for its Scrolling Overview. Two native Rust helpers (workspace profiles, compactor).
- Upstream warns: personal project, not focused on stability. Keep a fallback until the owner accepts it.

## Decisions (fixed)
- Packaging: flake input `ii-p3drovfx = { url = "github:P3DROVFX/ii-p3drovfx"; flake = false; }` (+ submodules only if I-0 shows they are needed at runtime), pinned by `flake.lock`. No copied tree. Local tweaks, if any, as `patches/ii-p3drovfx/*.patch` applied at build time.
- Shell selection via the existing option: add `"ii"` to `modules.desktop.shell` (enum). Hosts `desktop` and `laptop` set `session = "hyprland"`, `shell = "ii"`. halos1 untouched.
- Fallback: `specialisation.legacy-mango` (mango + dynisland, today's setup) stays on both hosts **until the owner accepts ii**. Then **ASK** whether to delete mango (`modules/desktop/sessions/mango/`) and dynisland (`modules/desktop/shells/dynisland.nix`, `shell/dynisland` or its current path).
- **Halo must not change.** Today every Hyprland host shares one config path (verified): `modules/desktop/hyprland.nix` writes `~/.config/hypr/hyprland.lua` from the shared template `hyprland.lua`, whose last line is an unconditional `dofile("/etc/hypr/hyprland-touch.lua")`; `hyprland-touch.nix` (hyprgrass, rotation, on-screen keyboard, tablet mode, the Surface touch device `iptsd-virtual-touchscreen-045e:001f`) is gated only by `session == "hyprland"`. Switching desktop/laptop to Hyprland as is would give them the Surface touch layer. So the config is layered first (I-3a) and halos1's output must stay **byte-identical** (same drvPath, same generated `hyprland.lua`).
- Layers: (1) base = shared template, all Hyprland hosts; (2) touch/tablet = new option `modules.desktop.hyprlandTouch.enable` (default false, halos1 sets true); (3) ii = ii's own Lua config in a separate file loaded only on ii hosts. ii's Lua is **never merged into the shared base**; this replaces the earlier "use as is or merge" question.
- Hyprland comes from the existing `hyprland` flake input (no `nixpkgs.follows`, keeps the Cachix cache valid; see `flake.nix` comment).

## Tasks

### I-0 Recon (read-only)
**Do** Clone to `/tmp/ii` (`git clone --recurse-submodules`). Read `sdata/` (Arch, Fedora, Nix dependency lists), `setup-ii-p3drovfx.sh` (everything it writes under `$HOME`), `.gitmodules`, `dots/.config/hypr/` (its Lua config and modules).
Versions: `nix eval --raw nixpkgs/nixos-26.05#matugen.version`, same for `quickshell`; the `hyprland` rev in `flake.lock` and its version vs 0.56.1; how the repo's Hyprland config (`hyprland.nix`, `hyprland.lua`, `hyprland-touch.nix`, `hyprland-mode.lua`) is wired today (director's reading is in Decisions: re-verify it).
Runtime writes: which paths the shell writes (`~/.config/illogical-impulse/config.json`, `~/.local/state/quickshell/...`, generated colors, a Python venv?). Is the `ii` config dir itself written to?
**Output** `notes/I-0.md`. **Done when** each dependency has a nixpkgs attr (or an **ASK**) and the Hyprland version question is answered.

### I-1 Package
**Do** `pkgs/ii-p3drovfx/default.nix`: installs `ii/` + helper scripts; Python env via `python3.withPackages` (replaces any venv); the two Rust helpers via `rustPlatform`; fonts and runtime tools on the wrapper `PATH`. Matugen too old in nixpkgs → **ASK** (overlay vs pinned fetch).
**Verify** `nix build .#ii-p3drovfx`; `nix-store -qR result | wc -l` recorded; no network at build.

### I-2 Module
**Do** `modules/desktop/shells/ii.nix`: option `modules.desktop.ii.enable`; links the config into `~/.config/quickshell/ii` (Home Manager); mutable state stays in `$HOME` (copy-once vs out-of-store symlink decided from I-0; written in the file header); autostart `qs -c ii`; do **not** install the self-updating `ii-p3drovfx` CLI.
**Verify** `nix flake check`; `drv-check.sh after`: **halos1 IDENTICAL**; `nixos-rebuild build` desktop and laptop.

### I-3a Layer the Hyprland config (no behaviour change)
**Do**
1. `hyprland-touch.nix`: gate on the new `modules.desktop.hyprlandTouch.enable` instead of `session == "hyprland"`; halos1 host file sets it `true`. Keep `hyprland-touch.nix` and `hyprland-mode.lua` as separate files (R-4 must not merge them into the base).
2. Template `hyprland.lua`: replace the unconditional `dofile("/etc/hypr/hyprland-touch.lua")` with a `@SESSION_EXTRAS@` placeholder; `hyprland.nix` fills it with exactly that same `dofile(...)` line when touch is enabled, and with ii's loader line on ii hosts, and with nothing otherwise.
3. Do not touch `hyprland-mode.lua`, `hyprland-touch.lua` content, `shell/halo/`, `modules/desktop/shell/halo.nix`.
**Verify** `drv-check.sh before` first; after: **halos1 IDENTICAL**; `nix eval --raw .#nixosConfigurations.halos1.config.environment.etc."hypr/hyprland-touch.lua".text` equal before/after; the generated `hypr/hyprland.lua` text for halos1 equal before/after (`nix eval --raw ...home-manager.users.jano.xdg.configFile."hypr/hyprland.lua".text`, diff). desktop/laptop unchanged until I-3b (still mango).
**Done when** the three diffs are empty.

### I-3b Hyprland session on desktop and laptop
**Do** Set `session = "hyprland"`, `shell = "ii"` on both host files (no `hyprlandTouch`); add `specialisation.legacy-mango` (old session + dynisland). Load ii's Lua config through the ii layer only. Enable the scrolling layout the way ii expects (check its config before touching `layout`). Duplicates between ii's Lua and the base template (binds, input, autostart): ii layer wins on ii hosts; list conflicts in the report.
**Verify** `nixos-rebuild build` both hosts; `drv-check.sh after`: **halos1 IDENTICAL** again. Owner checklist (yes/no): boots into Hyprland + ii; no touch/OSK/rotation daemons running (`systemctl --user list-units | grep -i halo` empty); bar, sidebar, launcher, Settings, Overview (classic and scrolling) open; wallpaper change recolors (Matugen); notifications arrive; volume/brightness OSD; lock; no write errors in `journalctl --user -b`; `legacy-mango` boot entry still works.
**Gate:** owner accepts ii, then answers the delete question above.

### I-4 Docs + update path
**Do** `docs/ii.md` (what, options, rollback via boot entry, known limits); `scripts/ii-update.sh` (bump input, rebuild check, patch rebase hint if patches exist). **Done when** `STATUS.md` updated and the report lists what is untested.
