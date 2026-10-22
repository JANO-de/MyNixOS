# Hyprland plan (Surface Pro 5)

**Goal:** iOS look (home screen, widgets, dock, blur, Dynamic Island) + Android mechanics
(Material You colors, quick settings/shade, gestures, customization) + a DeX-like desktop
mode when docked. Compositor = Hyprland, "feel" = the dynisland shell on top.

## Status
- [x] 1. Baseline session: `session = "hyprland"` (boot entry `hyprland` on the Surface)
- [ ] 2. Touch plumbing: hyprgrass, rotation, tablet switch, on-screen keyboard
- [ ] 3. Mode switch: `set_mode("tablet" | "desktop")` (Lua) + shell IPC
- [ ] 4. Shell: home screen, dock, control center, shade, app switcher, lock PIN pad
- [ ] 5. Theming: matugen colors into iOS-shaped components
- [ ] 6. Optional: Waydroid (Android apps)

## Knowledge
- **Lua config:** Hyprland 0.55 deprecated hyprlang; 0.56 uses Lua (`hyprland.lua`).
  Most guides and tools still use `hyprctl keyword`, which the Lua parser rejects
  (iio-hyprland is affected). Use `hl.*` / `hyprctl eval`. Check: `hyprctl configerrors`.
- **Nix:** use the flake package (plugins are tied to its exact version). `hyprpm` does
  not work on NixOS: plugins come from flake inputs with `inputs.hyprland.follows`.
  Never override the flake's nixpkgs (Cachix would miss). Cache must be active BEFORE
  the first build (pass it on the CLI once, below).
- **Session:** UWSM (`hyprland-uwsm`) starts `graphical-session.target`, which is what
  the `dynisland` user service waits for.
- **Touch:** Hyprland's own gestures are trackpad-only. hyprgrass adds touchscreen
  swipes, edge swipes, long-press drag/resize (alpha; keep the Type Cover at hand).
  SP5 touch = IPTS (`iptsd`, already enabled).
- **Rotation:** `hardware.sensor.iio.enable` is already on. Needs a helper that sets the
  monitor transform AND the touch transform together (Lua `hl.monitor` / `hl.device`).
- **Tablet switch:** `hl.bind("switch:on:<name>", fn, { locked = true })`; name from
  `hyprctl devices`. SP5 may not report one: check with `sudo evtest` (`SW_TABLET_MODE`).
- **Events:** `hl.on("monitor.added" | "monitor.removed" | "hyprland.start", fn)` drive
  the DeX-like switch. Titlebars for desktop mode: official `hyprbars` plugin.
- **Keyboard:** wvkbd is toggled by signals (`SIGRTMIN`); squeekboard auto-shows but needs
  text-input v2/v3 apps (no XWayland). Auto-show on Hyprland is unverified.
- **Overview/recents:** hyprtasking, Hyprspace, Hyprview (touchpad gestures; touch use untested).

## Files
| File | Purpose | State |
|---|---|---|
| `modules/desktop/hyprland.nix` | session, UWSM, portals, Cachix, writes `hyprland.lua` | done |
| `modules/desktop/hyprland.lua` | Lua template (binds, input, look) | done |
| `flake.nix`, `modules/desktop/default.nix`, `.../dynisland/default.nix`, `hosts/surface/default.nix` | input, enum, PATH, boot entry | patch |
| `modules/desktop/hyprland-touch.nix` | hyprgrass, iio helper, wvkbd | step 2 |
| `modules/desktop/hyprland-mode.lua` | `set_mode()`, switch/monitor events | step 3 |
| `shell/dynisland/services/Wm.qml` | add `hyprland` kind (`hyprctl -j`, event socket) | step 3 |
| `shell/dynisland/...` HomeScreen / ControlCenter / Switcher | iOS/Android UI | step 4 |
| `modules/theme.nix` | matugen output feeding the shell | step 5 |

## Step 1: apply and test
```bash
cd ~/Proyectos/MyNixOS
git apply hyprland-step1.patch          # then copy hyprland.nix / hyprland.lua to modules/desktop/
git add -A && nix flake lock            # adds the hyprland input only
sudo nixos-rebuild boot --flake .#surface \
  --option extra-substituters https://hyprland.cachix.org \
  --option extra-trusted-public-keys hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=
reboot                                  # pick "hyprland" in the systemd-boot menu
```
Checks: `hyprctl configerrors` is empty; `systemctl --user status dynisland`; `SUPER+Return`
opens alacritty; touch works. Black screen or hang: reboot into the default entry.

Expected gaps: dock running-app dots (Wm.qml has no Hyprland kind yet).

## Unverified (not evaluated, no Nix/Hyprland in the sandbox)
- Lua option names for border colors (isolated in `pcall`).
- Session name `hyprland-uwsm` (a wrong name fails at build time, not at login).
- Mesa from the Hyprland flake's nixpkgs (`hardware.graphics.package`) on the Surface.

## Sources
wiki.hypr.land (Start, Binds, Switches, Gestures, Events, Cachix) · wiki.nixos.org/wiki/Hyprland ·
github.com/horriblename/hyprgrass · github.com/JeanSchoeller/iio-hyprland · hyprland-plugins
