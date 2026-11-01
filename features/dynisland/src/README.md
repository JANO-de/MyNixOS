# DynIsland (Quickshell)

Dynamic Island + macOS dock + desktop widgets + iNiR-style settings, for mango (and niri).

## Install
Part of this repo: `modules/desktop/default.nix` imports `./shell/dynisland`, which
is active when `modules.desktop.shell = "dynisland"` (the default). Rebuild, then
`systemctl --user restart dynisland` after editing QML. Wallpapers go in
`~/Pictures/Wallpapers` (or change the folder in Settings).

## Keybinds
Declared in `modules/desktop/mango.nix` (mango) / `modules/desktop/niri.nix` (niri):
`Mod+Comma` settings, `Mod+I` island, `Mod+Space` launcher, `Alt+Space` spotlight,
`Mod+A` AI, `Mod+Q` quick settings, `Mod+V` clipboard, `Mod+Shift+L` lock.
By hand: `dynisland ipc <target> <function>`, e.g. `dynisland ipc settings toggle`.

## Compositor support
`services/Wm.qml` is the only file that talks to the compositor: `mmsg` on mango,
`niri msg` on niri. It replaces the old niri-only `services/Niri.qml`.

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
