# Halo handoff v2

Halo = iPadOS look + Android mechanics shell for Hyprland, written in Quickshell QML. Runs on the Surface.
Repo layout: `shell/halo/` (this shell) · `modules/desktop/shell/halo.nix` (service, `halo-ctl`, `halo-set-pin`, `halo-autokbd`).
Test run: `quickshell -p ~/halo` (or the systemd user service `halo`). IPC: `halo-ctl call <target> <fn>`.
IPC targets: `home` `shade` `overview` `settings` (toggle|open|close), `desktop show`, lock.

## Working notes
- Sandbox has no QML runtime: everything below was only syntax-balance-checked, never run. Say what is untested.
- When a change "doesn't take", grep the WHOLE repo for the filename (same-named stray file shadows the real one).
- `anchors { ... };` is illegal QML. No anchors on children of Row/Column.
- ListModel.get() inside a binding does not register a dependency; bump a `tick` property (see SetPageApps).
- Always list which files go where; the repo is 79 MB, so updates ship as `halo-update.tar.gz` (changed files only, repo-relative paths) plus a `.diff`.

## Done this session (ALL UNTESTED)
**Dock drag and drop**
- Home screen -> dock: in edit mode drag an icon onto the dock; the pill glows, a bar shows the insertion slot, release pins it (icon stays on the home screen too). Folders cannot be pinned.
  `Desktop.qml` (dockHit / dockIndexAt / refreshDrag / finish), `Dock.qml` publishes its geometry into `UI.dockRect|dockRowLeft|dockLead|dockStep`, `Apps.pinAtVisible()`.
- Dock -> screen: swipe an app up out of the dock (not in jiggle mode). `DockDrag.qml` draws the ghost icon and the target. Edge strip (80 px) = Slide Over, outer 35% = Split View, anywhere else / back over the dock = cancel.
  `UI.beginDockDrag/moveDockDrag/finishDockDrag`, `Tiling.qml` does the placement with `hyprctl --batch "dispatch ..."` (Slide Over: setfloating + resizeactive + moveactive, 420 px wide, 86% high; Split View: settiled + movewindow l/r). It uses `entry.execute()` on the current workspace, NOT `Home.launch` (tablet mode would open a fresh workspace).

**Settings app** (`HaloSettings.qml`, overlay window, Android-style)
- Open: gear in the shade, "Halo Settings" in the home-screen long-press menu, `halo-ctl call settings open`.
- Wide screens (>= 900 px): category list left, page right. Narrow: list, then page with back arrow. Esc goes back/closes.
- Pages (`SetPage*.qml`): Wi-Fi (list, connect, password field, forget, disconnect), Bluetooth (list, scan 8 s, pair/connect/forget), Display (brightness, rotation lock, colour scheme, interface size), Sound (volume, mute), Notifications (DND, clear all), Home screen (names, icon size, edit mode, wallpaper, reset), Security (lock now, PIN status), Apps (Dock / Home pills per app), Battery (level, time left, power mode), Storage (disks, RAM), Updates (NixOS generations, read-only), About.
- Helpers: `SetGroup/SetRow/SetSwitch/SetChips/SetButton`; services `Net.qml` (nmcli, bluetoothctl, powerprofilesctl) and `Info.qml` (device facts, one shell script).

## Files and where they go (all under `shell/halo/`)
| New | Changed |
|---|---|
| components/HaloSettings.qml, DockDrag.qml, SetGroup/SetRow/SetSwitch/SetChips/SetButton.qml, SetPage{Wifi,Bluetooth,Display,Sound,Notifs,Home,Security,Apps,Battery,Storage,Updates,About}.qml | shell.qml, components/Desktop.qml, Dock.qml, Shade.qml |
| services/Net.qml, Info.qml, Tiling.qml | services/UI.qml, Apps.qml |

## Next shell features
- Widget resize and stacks; weather, notes and search widgets; app widgets.
- Spotlight-style pull-down search on the home screen.
- Back-swipe from the screen sides; 3-finger gestures in the overview; window-to-card zoom animation (needs compositor support).
- Folders: drag an app out onto the page, multi-page folders, drop highlight.
- Library: search inside it, drag icons from the library to the home pages.
- Gesture tuning pass for the bottom swipe, based on feedback.
- Dock: drop highlight when dragging a dock icon back onto the home screen; Slide Over should stay on top across apps (needs `pin` or a special workspace); swapping/closing a Slide Over window.

## Settings still to do
Per-app notification control; sound output/input device picker; screen timeout and night light; idle/suspend lock timeout; one-tap rollback (needs polkit); storage cleanup; Wi-Fi advanced (static IP, hidden networks); Bluetooth device details.

## Product roadmap (the Halo app suite)
- Lock screen and Greeter polish (SDDM replacement, boot splash, face unlock later).
- Files, Gallery.
- Contacts, then Calendar, Clock, Calculator, Weather, Notes, Reminders.
- Camera, Voice recorder, Music and Video players.
- Browser, Mail, Messages, Maps.
- Store / Updates (Flatpak front end, generation rollback).
- System features: Stage-Manager windows, clipboard history, global search, Focus modes, accessibility, Pen support, KDE Connect, setup wizard, Waydroid.

## Review pass (static, still UNTESTED at runtime)
Checked: imports, every `Singleton.member` reference, unknown component types, brace balance, coordinate maths dock <-> Desktop <-> Tiling. Nothing blocking found. Fixed: `bluetoothctl info` ate the stdin of the device loop (Net.qml); Esc inside a TextInput did nothing (HaloSettings.qml); null guard (SetPageBattery.qml); opening home/overview/shade now closes Settings (UI.qml).
Known, not fixed: a Wi-Fi rescan rebuilds the list and clears a half-typed password; dragging the volume slider while muted stays silent; Wi-Fi password still visible in `ps`.

## Still untested
- NEW: everything above. First things to check, in order:
  1. Does the shell still start? (`quickshell -p ~/halo`, read the log for QML errors in the new files.)
  2. Dock: home -> dock drop, insertion index with and without the Apps button (desktop mode).
  3. Dock -> screen drag: the touch must stay grabbed by the dock window while the finger is far outside it. If coordinates stop arriving, DockDrag needs to take the input instead.
  4. Settings: open/close, back navigation, every page loads, Wi-Fi password connect, Bluetooth pair, brightness/volume sliders, power mode.
  5. Slide Over / Split View through hyprctl. Check `hyprland-mode.lua` for rules that force fullscreen/maximise in tablet mode; the classic dispatchers are assumed to work next to the Lua config.
- Glyphs: ≋ ✧ ⚑ ▦ ▮ ▤ ⟳ ⓘ ☀ ♪ ◔ 🔒 may render as boxes without a symbol/emoji font; swap for icons if so.
- Multi-monitor: every Dock writes `UI.dockRect`, the last one wins.
- From before: lock screen (SUPER+L, PAM, idle and suspend lock, Lock tile); control center and notification feel; edge strips versus hyprgrass; external monitor and Type Cover mode flips; Squeekboard with a hardware keyboard.

## Small chores
- Rotate the old surface-bootstrap password.
- DHCP reservation for the Surface.
- Wi-Fi connect passes the password as a command-line argument (visible in `ps` for a moment); move to `nmcli --ask` via stdin if that matters.

## Keyboard (squeekboard) notes
- Squeekboard keeps the user's X/hide as an override until the text field changes, so every field tap must call `SetVisible true` (idempotent). `Kbd.show()` now always asks (250 ms merge); it no longer trusts the mirrored `kbd-visible` flag (stale/0.4 s lag). `Kbd.hideQuiet()` hides without the floating button.
- Wi-Fi password now uses `SetInput` (was a bare TextInput without keyboard logic). UNTESTED.
