# Handoff: MyNixOS (`~/Proyectos/MyNixOS`)

## State
- Hosts: `desktop`, `laptop` (mango + dynisland) and `surface`.
- **Surface:** default boot = mango. The `hyprland` specialisation (SDDM session **Hyprland (UWSM)**) runs Hyprland 0.56.0 + hyprgrass + the **Halo** shell (Quickshell 0.3.0, `shell/halo/`). `modules.desktop.shell = lib.mkForce "halo"` there.
- **Direction:** a new tablet product. iPadOS look and polish, Android mechanics, Android-style Settings, DeX-like desktop mode. Niri is the fallback.
- **Verified by the user:** Hyprland, touch gestures, rotation, mode switch, home screen, dock, edge swipes, `SUPER+A`, shade (tiles, sliders).
- **Written, not yet built/tested:** the update below ("Latest update").

## Latest update (untested)
- **Control center** (`components/Shade.qml`, `ControlGrid.qml`, `services/Controls.qml`): iPad-style tiles. Long-press or *Edit* = jiggle mode, drag to reorder, `-` to remove, `+` chips to add back. Layout saved to `~/.config/halo/controls.json`. Tiles: Wi-Fi, Bluetooth, Airplane, DND, Rotation lock, Mode, Keyboard, Screenshot. Add a tile = add its id to `Controls.all` and a case in `info()` / `trigger()`.
- **Pull-down:** first pull = control center; drag the bottom grabber further = notification list (`Notifs.qml`, Halo is the notification daemon); drag it up = close. Notifications swipe sideways to dismiss; heads-up banner in `Banner.qml`.
- **Sliders** (`QsSlider.qml`): fill follows the finger 1:1, updates throttled to ~22 Hz, eased settle on release.
- **Keyboard:** `kbd-toggle [toggle|show|hide]` records `$XDG_RUNTIME_DIR/kbd-visible`; `KbdHandle.qml` shows a grabber + X above the keyboard (drag down >50 px or tap X). Heights `-H 420 -L 300` are set in `hyprland-touch.nix` and mirrored in `services/Kbd.qml`: tune both together. Unverified: whether the handle stacks above wvkbd (both on the overlay layer) and that `-H/-L` behave as assumed.
- `qt.platformTheme.name` fix; `scripts/`: `halo-dev.sh` (hot reload), `surface-deploy.sh` (rebuild + oneshot boot), `desktop-clear-oneshot.sh`, `ssh-config-surface.txt`.
- Not done: finger-tracked open of the shade/home from the screen edge (hyprgrass edge binds are discrete). Idea: thin Halo edge-strip windows that take the touch and drive the progress; needs a test of whether hyprgrass swallows edge touches first. Compositor animation curves (workspace swipe, windows) are not tuned yet.

## Known facts
- Touch device to transform: `iptsd-virtual-touchscreen-045e:001f`. `surface-rotate N` sets monitor + touch transform. Pinned apps: `Alacritty`, `org.kde.angelfish`, `com.adilhanney.saber`, `org.pwmt.zathura`, `org.pulseaudio.pavucontrol`, `btop` (missing ones hidden).
- Mode switch: `hyprctl eval 'set_mode("tablet"|"desktop")'`, state `$XDG_RUNTIME_DIR/hypr-mode`, `SUPER+SHIFT+T`. Binds: `SUPER+A` home, `SUPER+N` shade, `SUPER+K` keyboard.
- Fixed earlier: SDDM GLX crash (do not set `hardware.graphics.package = hyprNixpkgs.mesa`); Hyprland input compiles ~35 min if Cachix misses.

## Open
1. **Test the update above** (`scripts/surface-deploy.sh`, or `scripts/halo-dev.sh` for QML only). Verify `fingers = 2` bottom-edge bind.
2. **Home screen like iPadOS:** pages of icons (drag to rearrange, folders, jiggle/delete), page dots, widgets (clock, weather, calendar, notes, battery, media, search) incl. app widgets, widget gallery, Stage-Manager-like windowing in desktop mode.
3. **App switcher** (ToplevelManager cards, swipe up to close), **lock screen with PIN pad** (WlSessionLock), matugen theming (`Theme.qml` is static).
4. **On-screen keyboard:** wvkbd never auto-shows on text-field tap. Candidates: squeekboard (needs text-input v2/v3) or a Halo-native keyboard.
5. **Type Cover trigger for `set_mode`:** no `SW_TABLET_MODE`; diff `libinput list-devices` and `/sys/bus/surface_aggregator/devices` attached vs detached. External-monitor trigger untested; `layout = "monocle"` effect unverified.
6. **Small:** rotate the old `surface-bootstrap` password (in git history); DHCP reservation for the Surface (IP moves `.111`/`.115`); `sudo bootctl status | rg -i oneshot` on the desktop.
7. **Desktop/laptop (unchanged):** dock running-app dots, screenshot at login (cause unknown), mouse-wheel workspace switching, mango touch, `Dock.qml` `length` error.

## Product roadmap: the Halo app suite
Goal: ship it like a new tablet. Shared design language, one QML module `HaloUI` (tokens from `Theme.qml`: glass, radius 26, spring/ease-out-quint motion, large touch targets 48 px+, swipe-back, pull-to-refresh). Native apps are Qt6/QML (Kirigami-compatible) with a C++/Python backend where needed. Each app gets a `.desktop` file, an icon, and an optional home-screen widget. Android-style *Settings* (flat list, search on top, per-section pages) is intentional.

1. **Greeter / Login** (SDDM replacement, or Quickshell `WlSessionLock` + greetd): wallpaper with blur, clock, user avatar, PIN pad, password fallback, face unlock later (Windows Hello IR camera on the SP5 is possible via Howdy), power menu, on-screen keyboard, rotation aware, boots straight into tablet mode. Boot splash (Plymouth) matching the theme.
2. **Lock screen:** same clock/widgets as iPad, notifications list, media controls, camera/flashlight shortcuts, swipe up to unlock, PIN/pattern.
3. **Files:** sidebar (Recents, Favorites, Downloads, Documents, Pictures, Trash, external drives, network/SMB), grid/list/column views, multi-select with touch, drag and drop between windows, quick look preview (images, PDF, text, video), tags, zip/unzip, share sheet, search, Trash restore, storage overview. Backend: Qt + KIO or `gio`/udisks2.
4. **Gallery (Photos):** all photos timeline by date, albums, favorites, videos, memories, map view from EXIF, pinch-zoom, swipe between photos, edit (crop, rotate, filters, adjust), share, hide/delete with 30-day trash, import from USB/SD. Thumbnail cache; face/scene grouping later.
5. **Contacts:** list with alphabet scrubber, groups, avatars, vCard/CardDAV (Nextcloud/Google) sync via evolution-data-server or `vdirsyncer`, call/message/email actions, QR share, duplicates merge. Shared backend for Mail, Calendar, Messages.
6. **Settings (Android style):** search, Wi-Fi, Bluetooth, Display (brightness, scale, night light, rotation, refresh), Sound, Notifications (per app), Home screen and dock, Lock screen and security, Apps (permissions, defaults), Battery (health, usage, saver), Storage, Accounts, Keyboard and pen, Gestures, Desktop mode (DeX options, external display), Updates (NixOS generations, rollback), About. Backend: NetworkManager, BlueZ, UPower, logind, PipeWire, DBus.
7. **Calendar** (events, week/day/month, reminders, CalDAV), **Clock** (alarms, timer, stopwatch, world clock), **Calculator**, **Weather** (widget source), **Notes** (Saber is pinned today; pen-first with palm rejection, handwriting to text, PDF annotate), **Reminders/To-do**.
8. **Camera** (v4l2/libcamera, Surface front/rear cams, QR scan), **Voice recorder**, **Music/Media player** (MPRIS, widget, lock-screen controls), **Video player**.
9. **Browser** (Angelfish today; tabs overview, reader mode, touch gestures, extensions), **Mail**, **Messages** (Matrix/Signal bridge), **Maps**.
10. **Store / Updates:** Flatpak front end plus a curated tablet app list; update center with generation rollback.
11. **System features:** multitasking (split view, slide over, Stage-Manager-like windows in desktop mode), app switcher, drag and drop across apps, screenshots with markup, screen recording, clipboard history, Spotlight-style global search (apps, files, contacts, settings, calculator), Siri-like voice assistant hook (Claude/local), share sheet, Focus modes (DND schedules), per-app notification controls, accessibility (zoom, large text, screen reader via Orca, color filters), Pencil/pen support (Surface Pen: pressure, tilt, eraser, hover, barrel button), KDE Connect for phone continuity, backup/restore, first-run setup wizard (OOBE), parental/guest user, Waydroid for Android apps, auto-brightness and battery health charge limit.

Suggested order after the home screen: Lock screen + Greeter -> Settings -> Files -> Gallery -> Contacts/Calendar -> Camera -> Store -> the rest.

## How things work
- **Boot (Surface):** `scripts/surface-deploy.sh` runs `nixos-rebuild boot --target-host`, then `bootctl set-oneshot` on the newest `*-specialisation-hyprland` entry. Default entry stays mango. Remote activation needs `--sudo --ask-sudo-password`.
- **Halo dev loop (no rebuild):** `scripts/halo-dev.sh` rsyncs `shell/halo` to `~/halo` and runs `quickshell -p ~/halo` as `halo-test` (hot reload). IPC: `halo-ctl call home|shade toggle|open|close`, or `quickshell -p <path> ipc call ...`. `quickshell ipc --newest` does not work.
- **Hyprland from SSH:** `export HYPRLAND_INSTANCE_SIGNATURE=$(command ls /run/user/1000/hypr | rg -v chronos-shell | head -1)`; add `WAYLAND_DISPLAY=wayland-1 XDG_RUNTIME_DIR=/run/user/1000` for Wayland clients.
- **Files:** `modules/desktop/hyprland.nix` + `hyprland.lua`, `hyprland-touch.nix` (hyprgrass, `surface-rotate`, `kbd-toggle`, touch binds), `hyprland-mode.lua` (mode, layer rules, binds), `modules/desktop/shell/halo.nix` (service, `halo-ctl`, runtime tools), `shell/halo/` (`shell.qml`; `services/{Theme,Mode,Apps,UI,System,Controls,Notifs,Kbd}.qml`; `components/{Island,Dock,HomeScreen,Shade,ControlGrid,QsSlider,Banner,KbdHandle}.qml`). Singletons import as `qs.services` / `qs.components`.

## Environment notes
- zsh with `grep` -> `rg`, `ls` -> `eza`: use `command ls`. Flakes ignore untracked files: `git add -A` before every eval/rebuild.
- SP5: touch via `iptsd`, rotation via `hardware.sensor.iio.enable`; `monitor-sensor` over SSH fails (polkit), the user service is fine.
- The assistant has no Nix, Hyprland or Qt in its sandbox: everything is verified only by pasted output.
