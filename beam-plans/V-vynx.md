# V: ii-vynx as a second ii variant

Upstream: `github.com/vaguesyntax/ii-vynx` (GPL-3.0). p3drovfx is a fork of vynx. Goal: boot entry `vynx` on `desktop` and `laptop` that runs vynx without touching the p3drovfx setup.

## Verified by the director (clone of HEAD `9cdec0d`, 2026-09-19)
| Fact | Result |
|------|--------|
| Layout | `dots/.config/{quickshell/ii,hypr,matugen}`: same as p3drovfx |
| Hyprland config | Lua (`hypr/hyprland.lua`, `hyprland/*.lua`) |
| Shell name | `qsConfig = "ii"` (`hypr/hyprland/variables.lua`) |
| Submodule | `shapes` = `end-4/rounded-polygon-qmljs` @ `e31ec4cb`, same pin as p3drovfx |
| Self-start | `execs.lua` runs `qs -c $qsConfig`: removed by the module (systemd unit starts it) |
| Rust helpers | none (`scripts/rust-helpers.sh` absent): `iiRustHelpers` step is a no-op |
| Thumbnail script | `scripts/thumbnails/generate-thumbnails-magick.sh` present, patch applies |
| "Restart Shell" sed | target files absent in vynx: sed is a no-op (`|| true`) |
| Python imports | covered by `iiPython`, except `google` (optional gCloud feature) |
| Nix support upstream | `sdata/dist-nix` is explicitly "not for NixOS", WIP: unusable |
| Hashes | computed offline with a NAR hasher validated against the known p3drovfx hash |

## What was changed
- `pkgs/ii-vynx/default.nix` (rev `9cdec0d1...`, hash set), `pkgs/ii-shapes.nix` (shared pin, same content hash as before), `pkgs/ii-p3drovfx/default.nix` (uses the shared pin; no more branch tarball).
- `nix/packages.nix`: `ii-vynx` in packages and overlay.
- `modules/desktop/shells/ii.nix`: `modules.desktop.ii.variant`, `.variant` marker, vynx `execs.lua` patch.
- `hosts/{desktop,laptop}/default.nix`: `specialisation.vynx`.
- `docs/ii.md`.

## Tasks
### V-1 Build
```
git switch -c beam/vynx && git add -A
nix build .#ii-vynx && ls result/share/{quickshell/ii,hypr/ii,matugen/ii}
nix build .#ii       && ls result/share/quickshell/ii/modules/common/widgets/shapes | head
nix flake check
```
**Done when** both packages build (hashes already set; if Nix reports a mismatch, paste the real one and tell the owner).

### V-2 Hosts
```
beam-plans/drv-check.sh after      # all three hosts DIFFER (the ii activation script changed): expected
nixos-rebuild build --flake .#laptop && nixos-rebuild build --flake .#desktop && nixos-rebuild build --flake .#halos1
nix store diff-closures /nix/var/nix/profiles/system ./result
```
Rule 15 here: explain the diff. Expected: halos1 and p3drovfx hosts differ only in the home-manager activation script (ii marker); desktop/laptop gain `ii-vynx` in the specialisation closure.
**Done when** the three build and the diff is explained in the report.

### V-3 Owner boot test (owner runs, yes/no)
```
sudo nixos-rebuild test --flake .#laptop --specialisation vynx
journalctl --user -u ii -b | tail -30
```
- [ ] bar, sidebar, launcher, Settings open; wallpaper change recolors (Matugen)
- [ ] `systemctl --user status ii` active, only ONE `qs` process (`pgrep -a qs`)
- [ ] `dotfiles/laptop-vynx/` created and filled (`hypr/hyprland.lua`, `illogical-impulse/config.json`)
- [ ] default boot entry still p3drovfx and untouched (`dotfiles/laptop/` unchanged: `git status`)
- [ ] notifications, OSD, lock, screenshots, hypridle/hyprlock start

### V-4 Follow-ups (only if V-3 shows the problem)
- hypridle/hyprlock fail: copy `hypridle.conf`, `hyprlock.conf`, `hyprlock/` from `${iiPkg}/share/hypr/ii` in `iiHyprConfig` (copy-once, like `hyprland/`).
- Missing python module: add to `iiPython` in `ii.nix` (`ps.google-auth` for gCloud).
- Settings "restart" does nothing: check how vynx restarts (`grep -rn "Quickshell.reload\|qs kill" dots/.config/quickshell/ii`) and patch like p3drovfx's sed.
- Hyprland version complaints: `nix eval .#inputs.hyprland.packages.x86_64-linux.hyprland.version`; vynx states no minimum.
