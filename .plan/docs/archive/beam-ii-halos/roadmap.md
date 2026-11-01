# Roadmap

| Phase | Goal | Steps | Exit criteria |
|-------|------|-------|---------------|
| 1 | Hyprland settings page | 0-3 | Page changes live Hyprland values, no QML errors, persists after relogin |
| 2 | Profiles | 4 | Save, load, delete a profile from the UI |
| 3 | Displays | 5 | Monitor layout editable from settings, written to hyprmon.lua |
| 4 | Wallpaper picker + right-click menu | 6, 7 | Chosen options work, no idle CPU cost |
| 5 | Ship | 8 | `pkgs/ii-vynx` pinned to the fork, host builds, owner switches |

Principles: small and fast beats complete. Each feature opt-in via `Config.options`. Anything heavy needs the owner's approval.
Not planned: p3drovfx AI, Gmail/calendar, earbuds/phone services, dynamic island, video editor.
Upstream: merge vaguesyntax/ii-vynx `main` into `main` of the fork monthly, ask first.
