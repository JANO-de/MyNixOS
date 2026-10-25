# Halo handoff v4 (read ALL of this first)

## 0. How to work with this user (guidelines)
- **Write as little as possible while staying explanatory. Always send the commands to run.** Replies in English (user writes English; memory notes in Spanish).
- The repo is 79 MB, too big to upload. The user uploads `Nixos_tar.xz` (a snapshot, can be OLDER than what runs on the device). Ship changes as **`halo-update-N.tar.gz`** (only changed files, repo-relative paths `shell/halo/...`, plus HANDOFF.md when edited). Next number: **17**. Extract in the repo root: `tar xzf ~/Downloads/halo-update-N.tar.gz && scripts/halo-dev.sh`.
- No QML runtime in the sandbox: everything is only brace-checked. **Say what is untested.** Ask for logs; give one copy-paste command per test.
- When a change "doesn't take", grep the WHOLE repo for the filename (stray same-named file shadows the real one).
- QML rules learned: `anchors { ... };` is illegal; no anchors on children of Row/Column; `ListModel.get()` in a binding does not register a dependency (bump a `tick`); never read `screen` inside `visible` of a PanelWindow (binding loop, pass a string like `screenName`).
- **STANDING RULE (user, update 16): always port from the Android source code** (AOSP, android.googlesource.com), 1:1 behaviour/numbers; cite the file where a value comes from. **At the end of every task update this HANDOFF.md and ship it in the same `halo-update-N.tar.gz`.**
- Copyright: AOSP is Apache 2.0, fine to port behaviour; do not paste huge code blocks.

## 1. Project
Halo = iPadOS look + Android mechanics shell for Hyprland, written in Quickshell QML, running on a Microsoft Surface (NixOS, host `surface`, user `jano`, LAN `192.168.0.115`).
- Repo `MyNixOS`: `shell/halo/` (QML), `modules/desktop/shell/halo.nix` (service, `halo-ctl`, `halo-set-pin`, `halo-autokbd`), `modules/desktop/hyprland*.lua|nix`, `scripts/`.
- `shell/halo/shell.qml` instantiates per screen: Desktop, Island, HomeScreen, Dock, DockDrag, SplitDivider (new in update 12), Shade, Overview, HaloSettings, TopEdge, BottomEdge, Banner, KbdHandle, KbdButton (+ LockScreen once).
- Services (singletons, `services/`): UI, Apps, Mode (tablet/desktop from `$XDG_RUNTIME_DIR/hypr-mode`), Kbd, Net, Info, Tiling, Theme, Controls, Home...
- Run/test: `scripts/halo-dev.sh` (copies to `~/halo`, runs `quickshell -p ~/halo` as user unit `halo-test.service`). IPC: `halo-ctl call <target> <fn>`; targets `home shade overview settings` (toggle|open|close), `desktop show`, lock.
- SSH logs: `ssh jano@192.168.0.115 'journalctl --user -u halo-test -n 60 --no-pager | grep -viE "portal|kbd-height"'`.
- hyprctl over SSH needs: `export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr | head -1)`.

## 2. Facts about the device / compositor (verified in this session)
- **Hyprland 0.55+ with a Lua config.** `hyprctl dispatch X` evaluates `hl.dispatch(X)`: classic names (`settiled`, `movewindow l`, `keyword ...`) FAIL ("unknown request", "')' expected"). Use Lua dispatchers: `hl.dsp.window.float({action="enable"|"disable"|"toggle", window=...})`, `hl.dsp.window.move({direction="left"|"right"})`, `move({workspace=N, follow=true})`, `move({x=,y=,relative=false})`, `hl.dsp.window.resize({x=,y=,relative=false})`, `hl.dsp.focus({window=...})`, `hl.dsp.focus({workspace=N})`, `hl.dsp.layout("togglesplit")`. A Lua function also works: `dispatch function() hl.config({general={layout="dwindle"}}) end`. `hyprctl --batch "dispatch A ; dispatch B"` returns `ok` per command (log shows them).
- Window selector (`window = "..."`): `address:0x...`, `class:^(x)$`, `title:`, `pid:`; omitted = active window. `hyprctl clients` text: `Window <addr> -> title:`, `workspace: N (N)`, `class: X`, `floating: 0`, `size: w,h`.
- `hyprctl activeworkspace` first line here is `workspace 2 (2) on monitor eDP-1:` (NO word `ID`; field 2 = id). Named/special workspaces (home) are not numeric: never use `activeworkspace` to find the front app's workspace, read it from the window (`hyprctl clients`: `workspace:` line precedes `class:`).
- QML: `left` (and other Item properties) are FINAL: do not declare `property ... left` in a delegate (use `isLeft`). Squeekboard takes the bottom ~35% of the screen: windows are 596 px tall with the keyboard up (expected).
- Tablet mode (modules/desktop/hyprland-mode.lua): gaps_in=6 gaps_out=6, border 0, layout **monocle** (one window visible), **every launched app gets its own workspace**; desktop mode: gaps 5/10, dwindle. Halo "home" is an empty named workspace.
- Hyprgrass plugin for touch gestures; edge gestures handled by Halo (TopEdge/BottomEdge).
- Keyboard: **squeekboard** (halo-osk service, tablet mode only) over D-Bus `sm.puri.OSK0 /sm/puri/OSK0 SetVisible b true|false`; `kbd-toggle [show|hide|toggle]`, `kbd-watch` mirrors state into `$XDG_RUNTIME_DIR/kbd-visible` and `kbd-height`. Squeekboard keeps a hidden override after the X; every field tap must call `SetVisible true` (done: `Kbd.show()` always asks, 250 ms merge; `Kbd.hideQuiet()`; `SetInput.qml`). **Keyboard works (user confirmed).**
- Quickshell 0.3.0, Qt portal warning "Could not register app ID" is harmless; `kbd-height` file missing warning is harmless.

## 3. Updates shipped this session (all but the keyboard are UNTESTED unless stated)
| N | What |
|---|---|
| 1-3 | Dock drag & drop (home to dock, dock to screen), Settings app (12 pages). Dock drop home->dock: **works (user)**. Settings: loads. |
| 4-5 | Keyboard focus fixes (not in the uploaded tarball). |
| 6 | Kbd.qml (`show()` unconditional, `hideQuiet()`), SetInput.qml, SetPageWifi uses SetInput. **Works.** |
| 7 | DockDrag binding-loop fix, dock swipe-up easier (22 px, preventStealing), split zones. |
| 8 | Tiling.qml moved to Lua dispatchers (the log proved classic ones failed). |
| 9-10 | Split: resize 50/50 second step; wait for new window; log via `systemd-cat -t halo-tiling`. |
| 11 | Tiling targets windows by address (class for running apps, "new address" for launches). Result unknown. |
| 12 | **Android split screen port**: half-screen drop zones (Slide Over removed from dock drag), `SplitDivider.qml` (handle, snaps 0.3/0.5/0.7, edge <15%/>85% dismisses via `move({workspace="empty"})`), split state file `$XDG_RUNTIME_DIR/halo-split` ("L R ws W H"), polled 1 s. **After this update the user reports the whole shell disappeared.** |
| 13 | Tiling: workspace of the front app read from its window (fixes: windows stayed on separate workspaces). **Split works (user).** |
| 14 | Tiling: `activeworkspace` parsing fixed (no `ID` word) so the divider shows; monocle restored when a split ends (tablet). **Works.** |
| 15 | SplitDivider: binding loop on `shown` removed (no `screen` read), logs `halo-split snap x= r=`. **Divider, snaps 30/50/70, edge dismiss: works (user).** |

## 4. Status (after update 15)
Resolved: shell vanished because `DockDrag.qml` declared `readonly property bool left` (FINAL property) -> renamed `isLeft`. Split now works end to end: drag from dock to a half, both apps on the same workspace 50/50 (dwindle), divider with handle, snaps 30/50/70, edge dismiss (<15% / >85%), monocle restored in tablet mode.
Pending in split: (a) divider must be non-interactive while a resize runs (Android: no stuck divider on fast resize); (b) **split select staging** (Android `SplitShortcut` -> `startSplitSelection`: first app is staged, pick the second one; used when no app is in front, e.g. from home). Do both, then the taskbar (section 5/6).
The next step needs the repo files `Dock.qml`, `UI.qml`, `Apps.qml`, `Home*.qml`, `Overview.qml`, `shell.qml`: ask the user to upload a fresh `Nixos_tar.xz` or cat them.

## 5. Android port: source is reachable (user wants 1:1 "from the source")
User decision: port **both** Android taskbar designs, **split first**, then the dock.
- `android.googlesource.com` is fetchable with web_fetch but only by following links that appeared in earlier results (do not build URLs). Start: `https://android.googlesource.com/platform/packages/apps/Launcher3/+/refs/heads/main` (dirs `quickstep/`, `src/`). Frameworks: `https://android.googlesource.com/platform/frameworks/base/+/192b4532c5c6%5E%21/` (diff page, has links; WM Shell split code lives in `libs/WindowManager/Shell/src/com/android/wm/shell/common/split/` = `DividerSnapAlgorithm`, `DividerView`, `SplitLayout`, `SplitWindowManager`, `SplitScreenConstants`; and `.../splitscreen/` = `StageCoordinator`, `SplitScreenController`). gitlab.com and cs.android.com block the fetcher. Taskbar: `quickstep/src/com/android/launcher3/taskbar/` (`TaskbarDragController`, `TaskbarView`, `DesktopTaskbarRecentAppsController`).
- Learned so far from the source: divider is made non-interactive while a resize transition runs (prevents "stuck if resize split quickly"); snap targets come from `DividerSnapAlgorithm` (`SNAP_TO_START_AND_DISMISS`, 30/70, 50/50, 70/30, `SNAP_TO_END_AND_DISMISS`, `SNAP_TO_NONE`); `setDivisionPosition` notifies when the target means "dismiss"; taskbar drag starts a system drag (ClipData with activity intent) and WM Shell shows the split drop zones.
- Still to read before claiming 1:1: exact snap fractions/thresholds and divider size/handle dimensions (res `dimens.xml`), drop-zone visuals (`DragAndDropPolicy`/`SplitDragPolicy`), taskbar icon long-press popup (`PopupContainerWithArrow`, "Split screen" item), recents/running icons in the taskbar, "split select" staging (first app staged, pick second from Overview).

### Learned from AOSP (update 16 research, Launcher3 `quickstep/src/com/android/launcher3/taskbar/`, `.../splitscreen/SplitShortcut.kt`)
- **Layout (`TaskbarView.java`)**: LTR order = [All Apps button][divider only if there are NO recents][hotseat (pinned) icons][divider if recents exist][recents/running icons]. When too many icons fit, an overflow button replaces the last ones. Icon touch size >= `taskbar_icon_min_touch_size`, spacing `taskbar_icon_spacing` (read `res/values/dimens.xml` for numbers before coding). Right-click (mouse secondary button) on an icon = same menu as long-press.
- **What is shown (`TaskbarRecentAppsController.kt`)**: predicted apps are removed. Fullscreen/tablet mode: the last `MAX_RECENT_TASKS = 2` recent tasks, current task excluded, de-duplicated against pinned packages. Desktop mode: all running tasks (stable first-seen order; a pinned app that is running merges into its pinned icon with a running/minimized state; others appended after the pinned ones). Running state per app: RUNNING / MINIMIZED / NOT_RUNNING (drawn as the indicator).
- **Long-press menu (`TaskbarPopupController.java`)**: notifications + deep shortcuts, then system shortcuts in this order: App info, split options (Split left/right/top; NOT shown in desktop windowing), Bubble, and in desktop windowing "New window" + "Manage windows" (only apps that support multi-instance). Menu items can be dragged out (deep shortcuts).
- **Split from the menu**: if an app is in front the item launches the split immediately (app on the chosen side, existing app on the other); if the launcher/home is in front (`mAllowInitialSplitSelection`) it starts **split selection**: the item becomes the staged first app (`SplitSelectSource`: view, icon, intent, position) and the user picks the second app.
- Still to read: `TaskbarDragController.java` (long-press then drag, drop zones), `TaskbarStashController.java` (stash/unstash), `ManageWindowsTaskbarShortcut.kt`, `res/values/dimens.xml`, `SplitSelectStateController` (staging UI) and `TaskbarAllAppsButtonContainer`.

## 6. Roadmap (in order)
1. ~~Fix the vanished shell~~ DONE (updates 13-15).
2. **Split screen 1:1**: drag-to-split, divider, snaps, dismiss, monocle restore are DONE. Left: split select staging from home/long-press menu; divider disabled during resize; 2-app swap/close behaviour.
3. **Dock = Android taskbar (tablet)**: pinned + recent/running apps with running dot, long-press popup menu (app shortcuts, "Split screen", multi-window list), drag icon (long-press then drag) to split zones, stash/unstash behaviour, All-apps button.
4. **Dock = Android desktop windowing (15/16)**: per-app window previews on tap/hover when an app has several windows ("manage windows"), interact with every window (focus, close, move to split), live thumbnails (Quickshell `ScreencopyView` on `Toplevel`), window controls.
5. Old roadmap: widget resize/stacks (weather, notes, search); Spotlight-style pull-down search; back-swipe from the sides; 3-finger gestures in overview; window-to-card zoom (needs compositor support); folders (drag out, multi-page, drop highlight); library search + drag to home; dock drop highlight when dragging back to home; gesture tuning.
6. Settings still to do: per-app notification control; sound output/input picker; screen timeout, night light; idle/suspend lock timeout; one-tap rollback (polkit); storage cleanup; Wi-Fi advanced (static IP, hidden); Bluetooth device details.
7. Product suite: lock screen/greeter polish (SDDM replacement, boot splash, face unlock); Files, Gallery; Contacts, Calendar, Clock, Calculator, Weather, Notes, Reminders; Camera, Voice recorder, Music/Video; Browser, Mail, Messages, Maps; Store/Updates (Flatpak, generation rollback); Stage-Manager windows, clipboard history, global search, Focus modes, accessibility, Pen, KDE Connect, setup wizard, Waydroid.

## 7. Settings app summary (update 1-3)
`HaloSettings.qml` overlay (open: gear in shade, home long-press "Halo Settings", `halo-ctl call settings open`). Wide >= 900 px: list left, page right; narrow: list then page with back. Pages `SetPage{Wifi,Bluetooth,Display,Sound,Notifs,Home,Security,Apps,Battery,Storage,Updates,About}.qml`; helpers `SetGroup/SetRow/SetSwitch/SetChips/SetButton/SetInput`; services `Net.qml` (nmcli, bluetoothctl, powerprofilesctl), `Info.qml`. Tap outside a field hides the keyboard (UI.inputTapAt/inputFocusAt guard).
Known, not fixed: Wi-Fi rescan clears a half-typed password; volume slider while muted stays silent; Wi-Fi password visible in `ps` briefly (nmcli arg).

## 8. Split implementation details (current code, update 15)
- Drag from dock (`Dock.qml` MouseArea, swipe up > 22 px, `UI.beginDockDrag/moveDockDrag/finishDockDrag`), `DockDrag.qml` draws the dragged icon + 2 half panels (zone `split-left|split-right` above the dock).
- `Tiling.splitView(item, side, screen)`: needs a front app (`ToplevelManager.activeToplevel`); otherwise just opens the app. `infoProc` snapshots workspace + window addresses; `run()` activates/launches the app and starts a shell script: wait for target window (class match for running apps; new address for launches) -> `hyprctl --batch` (layout dwindle fn, move to workspace, float disable, move direction, focus) -> 0.5 s -> resize to half -> detect the other window on the workspace -> write `halo-split`.
- Gap math: `boundaryX(r) = gapOut + r*(W - 2*gapOut)`; left width = `r*(W-2*gapOut) - gapIn`; tablet gaps 6/6, desktop 10/5.
- Logs of every hyprctl call: `journalctl --user -t halo-tiling -n 20 --no-pager`; state: `cat /run/user/1000/halo-split`; layout check: `hyprctl getoption general:layout`; windows: `hyprctl clients | grep -E "class|workspace:|floating|size:"`.
- Split works since update 13/14 (confirmed). Front workspace = workspace of the front app's window (infoProc), not `activeworkspace`. `clearSplit()` restores monocle in tablet mode. Divider logs `halo-split snap` in the quickshell journal.

## 9. Small chores
Rotate the old surface-bootstrap password; DHCP reservation for the Surface; Wi-Fi connect via `nmcli --ask` stdin instead of argv; glyphs (≋ ✧ ⚑ ▦ ▮ ▤ ⟳ ⓘ ☀ ♪ ◔ 🔒) may render as boxes without a symbol/emoji font; multi-monitor: last Dock wins `UI.dockRect`; lock screen (SUPER+L, PAM, idle lock), control center feel, edge strips vs hyprgrass, external monitor/Type Cover mode flips, squeekboard with hardware keyboard are all still untested.
