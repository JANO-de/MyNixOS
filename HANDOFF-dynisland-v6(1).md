# MyNixOS / dynisland handoff v6

Repo: ~/Proyectos/MyNixOS (re-upload as MyNixOS_tar.xz, exclude .git/result*)
QML root: modules/desktop/shell/dynisland/ · shell = dynisland (end4pc disabled) · host `desktop`
Rebuild: `sudo nixos-rebuild switch --flake .#desktop`
Live instance is a **systemd --user service** (`systemd.user.services.dynisland` in dynisland/default.nix),
NOT the `dynisland start/dev` CLI. After editing files: `systemctl --user restart dynisland`.
Logs: `systemctl --user status dynisland` / `journalctl --user -u dynisland`.

## GUIDELINES
- TEXT AS LITTLE AS POSSIBLE, USE NO TOKENS UNLESS NECESSARY
- Do as little work as possible unless allowed or needed; only once until allowed/needed again
- ALWAYS share and present output files (present_files) so user can download them
- Check everything before sending; say what is untested (sandbox has no QML/niri runtime)
- Ask before creating/changing the TODO-list
- `anchors { ... };` is illegal QML (no stray semicolons)
- Always list which files go where; user copies them manually
- **CRITICAL LESSON**: QML resolves `qs.services`/`qs.island` by directory; a same-named file in the
  wrong folder (e.g. `services/ControlsCard.qml`) can silently shadow/duplicate the real one and keep
  rendering stale UI for days even after the real file is edited and the service restarted. When a
  change "doesn't take," grep the WHOLE repo for the filename, not just the expected path.

## Confirmed working (v5 fixes)
- services/ControlsCard.qml delete + restart fixed the stale-UI issue. Confirmed.
- ClockCard.qml layout fix (zero-width clipped wrapper, weather text wraps/centers) — confirmed fixed.
- fullHeight 234, no clipping/overlap — confirmed.
- gammastep / wf-recorder / power profile — confirmed working end-to-end.
- QuickTile size (58→46) + Icon.qml NativeRendering (scratched-icon fix) — delivered, not yet confirmed.

## Done this session (batch 3 + scroll pass) — ALL UNTESTED
Delivered as dynisland-batch3.zip then dynisland-scroll.zip (contents below); diff against repo before copying.

- **Recent files widget**: `services/Recent.qml` (parses `~/.local/share/recently-used.xbel`) +
  new DesktopWidget in `modules/widgets/DesktopWidgets.qml`. Toggle in Settings > Widgets.
- **Multi-wallpaper per workspace**: `services/Wall.qml` (new) wraps `Config.appearance.wallpaper`;
  `Config.appearance.perWorkspace` + `wsWallpapers` map. Wired into Wallpaper.qml, DesktopMenu.qml,
  WallpaperSlide.qml. Toggle in Settings > Appearance.
- **USB/mount notifications**: `services/Usb.qml` (new), polls `lsblk` every 3s, notify-send on
  connect/mount/unmount/remove. Toggle `Config.system.usbNotify` in Settings > System.
- **Update indicator**: `services/Updates.qml` (new), checks `flake.lock` mtime vs
  `Config.system.updateDays` (default 7). Shows in ClockCard + a QuickPage tile; click runs
  `Config.system.updateCmd` in a terminal. Settings in Settings > System.
- **Drag-drop file shelf**: new DesktopWidget in DesktopWidgets.qml, `Config.widgets.shelfItems`
  persists dropped file paths; click to open, drag out to copy, right-click to remove.
- **Quick note popup**: NotePanel.qml already existed but wasn't wired up — added to
  `PanelView.qml`'s `files` map, a QuickPage tile, and `ipc call tools note`.
- **Weather accent shift**: `Weather.tint` (new, in Weather.qml) tints ClockCard's today-highlight
  and weather icon by condition. Toggle `Config.island.weatherAccent` in Settings > Island.
- **Smoother animations**: longer eased opacity fades across island view files, content
  scale-in (0.95→1) on FullView/PanelView/TrayMenuView, reduced pill morph overshoot (0.9→0.7).
- **Mouse-wheel scrolling**:
  - ValueSlider/SSlider (volume, brightness, all settings sliders): wheel nudges the value
    (proportional step), separate from drag.
  - DesktopMenu wallpaper strip + Settings WallpaperSlide: smooth wheel/drag scroll,
    auto-applies the wallpaper ~0.2s after scrolling settles.
  - Settings sidebar (page nav list): vertical wheel scroll (Flickable + WheelHandler).
  - Island tray strip (TrayStrip.qml): horizontal wheel scroll if icons overflow 150px.
  - Dock icon bar: wheel pans sideways, only once the bar is wider than the screen.

## Files changed this session (copy to real repo)
components/{Icon,SSlider,ValueSlider}.qml
config/Config.qml
modules/background/{DesktopMenu,Wallpaper}.qml
modules/dock/Dock.qml
modules/island/{ActivityFullView,ActivityView,ClockCard,FullView,IdleView,Island,NotifView,OsdView,
  PanelView,QuickPage,QuickTile,TrayMenuView,TrayStrip}.qml
modules/settings/{AppearancePage,IslandPage,Settings,SystemPage,WallpaperSlide,WidgetsPage,
  WidgetsPreview}.qml
modules/widgets/DesktopWidgets.qml
services/{Recent,Updates,Usb,Wall,Weather}.qml   (Recent/Updates/Usb/Wall are NEW files)
shell.qml

DELETE: modules/desktop/shell/dynisland/services/ControlsCard.qml (stale duplicate, confirmed fixed by deleting)

## TODO (ask before editing)
- Confirm all of batch 3 above actually works after copy + restart (first real test pass)
- Confirm QuickTile size/Icon.qml NativeRendering fixed the scratched-icon look
- ClockCard may clip at the bottom when the update-indicator row shows (new row added under TrayStrip) — watch for this
- Weather accent: confirm tint looks right across conditions (sunny/rain/snow/etc.)

## Refs
- Forge-TUI reference repo: https://github.com/rsaryev/localix (also JANO-de/Forge-TUI)

## To resume
Upload tarball, confirm/deny each batch-3 item above, paste any
`journalctl --user -u dynisland` errors, say what's next.
