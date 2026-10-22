# Handoff: MyNixOS (`~/Proyectos/MyNixOS`)

## State
- Hosts: `desktop`, `laptop`, `surface`.
- `desktop` and `laptop`: mango + dynisland.
- `surface`: mango + dynisland (tablet experiment). This is a Surface-only override and should stay local to that host unless explicitly reverted.
- The laptop rebuilt and switched successfully. The desktop boots again (login hang fixed, see Done). The Surface has not been rebuilt with Hyprland yet.
- **Direction:** Hyprland on the Surface (iOS look, Android mechanics, DeX-like desktop mode). Plan and file list: `HYPRLAND_PLAN.md`. Niri is the fallback.

## Done
- Portal conflict: removed the `Inhibit` line in `modules/desktop/mango.nix`.
- Keybind conflicts: stack binds moved to `SUPER+ALT+Left/Right`; removed the `XF86AudioPause` bind.
- Screenshots: the only bind left is `CTRL+Home` (region only).
- Touch: `touch_enable = 1` and `touch_enable_mouse_emulation = 1` added to the mango settings. These apply only when `session = "mango"`, so the Surface does not use them.
- Greeter: `sddm-astronaut` with `purple_leaves` in `modules/desktop/default.nix` (still the X11 greeter). The Surface keeps its patched catppuccin theme with the on-screen keyboard. The stray `modules/desktop/greeter.nix` was removed.
  - Other themes: `astronaut`, `black_hole`, `japanese_aesthetic`, `cyberpunk`, `post-apocalyptic_hacker`, `pixel_sakura_static`, and the animated `pixel_sakura`, `hyprland_kath`, `jake_the_dog`.
  - Preview screenshots: `https://github.com/Keyitdev/screenshots/blob/master/sddm-astronaut-theme/master/<theme>.png`

- Desktop login hang (SDDM "no screens found"): `hardware.nix` applied the laptop's PRIME bus IDs to the desktop, a single GTX 1060 with no iGPU. PRIME is now laptop-only; NVIDIA is per host (desktop Pascal: `legacy_580`, `open = false`; laptop RTX 3050 could use a newer driver, untested).
- Elements drive: `nofail` alone still fails `nixos-rebuild switch` when the drive is absent; `x-systemd.automount` avoids it. Same UUID on both machines, so only one at a time.
- Hyprland step 1 written, untested: `modules/desktop/hyprland.nix` + `hyprland.lua`, `hyprland-step1.patch` (flake input, session enum, dynisland PATH, Surface boot entry `hyprland`).

## Latest progress
- Fixed the stale DynIsland/Niri assumptions by preferring the Mango path in the shell logout command and by adding a compositor-aware WM settings page (`WMPage.qml`) that detects the active session (`MangoWM` vs `niri`).
- Added the 1920x1080 portrait monitor rule for the desktop host: Mango uses `rr:1` (90° CCW), matching the physical desk setup.
- Kept the repo configuration host-aware: the desktop/laptop default remains mango + dynisland, and the 90° rotation is encoded in `modules.desktop.mango.monitorRules` instead of leaking into other hosts.

## Open
- **Dock:** logs showed `Dock.qml` errors (`length` of undefined), so the running-app dots are unconfirmed. If missing, paste `journalctl --user -u dynisland | rg Wm:`.
- **Screenshot at login:** it happens and the cause is unknown. It is not the `Home` key alone anymore.
- **Touch on mango:** untested on the Surface. Mango has no touchscreen edge gestures and no on-screen keyboard inside the session.
- **Not ported:** mouse-wheel workspace switching.
- **Warning:** `qt.platformTheme` should become `qt.platformTheme.name`.
- **Security:** the old `surface-bootstrap` plaintext `initialPassword` is still in git history. Change it if not already changed.

## Tablet WM research
The Surface is currently testing mango + dynisland as a tablet-focused setup; niri remains the fallback if the Mango route becomes unstable.

Mango itself: native touch input since 0.16 (forwarded to `wl_touch` clients, optional mouse emulation, device pinning with `device_rule=...,monitor:...`). `gesturebind` is documented for touchpad swipes with 3 or 4 fingers only; no touchscreen gestures, tablet mode, auto-rotation or session on-screen keyboard found, and no tablet fork or plugin for mango.

### Closest to a tablet tiling WM
- **Hyprland + hyprgrass.** Plugin adding touchscreen workspace swipes, edge swipes, multi-finger gestures and custom commands, with a tunable edge margin. Still alpha. An Omarchy discussion also describes a Python daemon that translates touchscreen events into Hyprland dispatchers on Surface Pro-class devices.
  - https://docsearch.algolia.com/mcp/docs/repo/horriblename/hyprgrass
  - https://github.com/omacom/omarchy/discussions/1659
- **Niri.** Stock niri has touchpad gestures but no touchscreen gestures yet. An open pull request adds touchscreen swipe, pinch, rotate, tap and zoned edge swipes, recognized in the compositor. Merge status not checked. Since the Surface runs the niri chronos fork, cherry-picking that pull request into the fork is probably the cheapest route.
  - https://github.com/niri-wm/niri
  - https://github.com/niri-wm/niri/pull/3771
- **Wayfire.** Touchscreen handling rewritten with swipe and pinch gestures under 3 fingers (suits edge swipes). Source is from 2021, so current state is unknown. Stacking-style compositor with tiling as an option.
  - https://wayfire.org/2021/01/29/Wayfire-0-7.html

### Full touch desktops (not tiling)
- **KDE Plasma.** Actions bound to swipes from each screen edge, on-screen keyboard and tablet mode. Works out of the box.
  - https://en.windowsnoticias.com/KDE-Plasma-optimizes-for-touch-and-natural-gestures/
- **Phosh / Plasma Mobile.** Touch-first, but Phosh maximizes every window, which suits phones more than a Surface Pro.
  - https://ivonblog.com/en-us/posts/linux-phosh-de-introduction/

### Other options considered
- **lisgd** (touchscreen gesture daemon) plus **wvkbd** (on-screen keyboard, toggled by `SIGRTMIN`): compositor-independent, works with `mmsg dispatch`. Gestures fire only after release, and it has no tablet mode or rotation. You declined lisgd.

### Recommendation
Keep niri on the Surface and take the touch gestures from the niri pull request. Hyprland + hyprgrass is the alternative (new config and shell integration needed). Plasma is the fallback with no development.

**Update:** the direction is now Hyprland (see `HYPRLAND_PLAN.md`). Hyprland needs the Lua config (0.55+) and flake-pinned plugins (hyprgrass for touch).

**Next step:** apply the patch, boot the `hyprland` entry on the Surface, check `hyprctl configerrors` and `systemctl --user status dynisland`.

## Environment notes
- Shell is zsh with `grep` aliased to `rg` and `ls` to `eza`. Use `command ls`, `command grep` and `rg -g '*.nix'`.
- First Hyprland build needs the Cachix flags on the CLI (see `HYPRLAND_PLAN.md`); use `nixos-rebuild boot`, not `switch`, on the Surface.
- Flakes ignore untracked files: run `git add -A` before every rebuild.
- Nothing in this tree has been evaluated by me; the sandbox has no Nix.
