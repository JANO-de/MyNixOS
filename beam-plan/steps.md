# Steps

Every step starts with `ask-first.md`. Check with the owner, then build.

## 0. Setup (owner runs)
```
mkdir -p ~/Proyectos && cd ~/Proyectos
git clone https://github.com/JANO-de/ii-halos.git && cd ii-halos
git checkout -b feat/hyprland-page
git remote add p3 https://github.com/P3DROVFX/ii-p3drovfx.git && git fetch p3 dev
```
Check: `git log --oneline -1` shows `9cdec0d1`.

## 1. Backend: configurator + service
- Files: `scripts/hyprland/hyprconfigurator.py`, `services/HyprlandConfig.qml`.
- Source: `git checkout p3/dev -- dots/.config/quickshell/ii/scripts/hyprland/hyprconfigurator.py dots/.config/quickshell/ii/services/HyprlandConfig.qml`.
- Trim the service to `set()` and `setMany()` plus the write queue. Remove welcome/keyboard persistence and anything needing missing imports.
- Check: `python3 <script> --file ~/.config/hypr/hyprland/shellOverrides/main.lua --set "general.gaps_in" "5"`, then `hyprctl reload` and `hyprctl getoption general:gaps_in -j`.
- Ask: which keys format the script expects; show its `--help`.

## 2. Page skeleton
- File: `modules/settings/HyprlandConfig.qml` (pattern: `AdvancedConfig.qml`).
- Register in `settings.qml` (icon `window`, before Advanced); renumber page indexes.
- Check: `qs -p ...settings.qml` shows the page, no QML errors.

## 3. Controls
Order: gaps in/out, border size, rounding, blur, animations on/off, input (touchpad natural scroll, `kb_layout`), misc.
- Each control reads the live value on page open (`hyprctl getoption <key> -j`) and writes with `HyprlandConfig.set`, then reload.
- One commit per group. Check each: change in UI -> `hyprctl getoption` matches.

## 4. Profiles
- Save/load/delete named copies of `~/.config/illogical-impulse/config.json` in `~/.config/illogical-impulse/profiles/<name>.json`.
- Ask first: include `shellOverrides/main.lua` in a profile? where in settings (Advanced or own page)?
- Reference: p3 `modules/settings/configs/PresetsConfig.qml` (read only, do not copy wholesale).

## 5. Displays (hyprmon)
- Page `modules/settings/DisplaysConfig.qml`: list from `hyprctl monitors -j`; resolution, refresh, scale, position, transform.
- Writes go to `~/.config/hypr/hyprmon.lua` (check the file format first; ask the owner for a sample).
- Reference: p3 `scripts/hyprland/monitor_manager.py`, `modules/common/models/hyprland/MonitorConfigOption.qml`.

## 6. Wallpaper picker styles
- Ask which styles/options. Edit `modules/ii/wallpaperSelector/*`. Add config keys in `Config.qml` first.
- Reference: p3 `modules/ii/wallpaperSelector/`; copy no file whole.

## 7. Right-click background menu
- Ask which entries. New `modules/ii/background/ContextMenu.qml`, a `MouseArea` with `Qt.RightButton` on the background root.
- Reference: p3 `modules/ii/contextMenu/`, `modules/ii/background/desktopMenu/` (design only).

## 8. Nix pin
Section 6 of `guidelines.md`. Only when steps 1-3 are stable and committed. Owner pushes the branch first.
