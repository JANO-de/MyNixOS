# DynIsland (Quickshell)

Dynamic Island + macOS dock + desktop widgets + iNiR-style settings, for niri.

## Install (NixOS / home-manager)
1. Copy this folder to `modules/desktop/shell/dynisland/`, import `./default.nix`.
2. Disable eww and the python notification server (only one process may own
   `org.freedesktop.Notifications`).
3. Put wallpapers in `~/Pictures/Wallpapers` (or change the folder in Settings).
4. Rebuild. Test without the service: `qs -c dynisland`.

## niri keybinds (config.kdl)
    Mod+Comma  { spawn "qs" "-c" "dynisland" "ipc" "call" "settings" "toggle"; }
    Mod+I      { spawn "qs" "-c" "dynisland" "ipc" "call" "island" "toggle"; }

## Where things live
| Want to change...            | Edit                                   |
|------------------------------|----------------------------------------|
| a setting / default          | `config/Config.qml`                    |
| island look & modes          | `modules/island/Island.qml`            |
| island expanded controls     | `modules/island/ControlsCard.qml`      |
| cava styles                  | `GlowRing.qml`, `Visualizer.qml`       |
| dock                         | `modules/dock/`                        |
| desktop widgets              | `modules/widgets/DesktopWidgets.qml`   |
| settings pages               | `modules/settings/`                    |
| colors (matugen)             | `services/Theme.qml`                   |

Debug: `qs -c dynisland` prints QML errors to the terminal.
Icons in the dock need a Qt-visible icon theme (e.g. Papirus via qt6ct / QT_QUICK).
