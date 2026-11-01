# Architecture

## Tree

- `flake.nix`: inputs + thin outputs. `nixosConfigurations` = one per folder in `hosts/`; packages, apps, overlay and the dev shell come from `modules/pkgs`.
- `hosts/{desktop,laptop,halos1}/`: per-host switchboard (`default.nix` sets `modules.*` flags) + hardware + host-only modules. `hosts/<host>/dotfiles/`: app-written configs kept in git.
- `modules/`: every capability (see `layout.md`), auto-imported by `modules/default.nix`.
- `modules/desktop/halo/src/`: Halo QML shell (rsync source of `halo-dev`). `modules/desktop/dynisland/src/`: dynisland QML.
- `modules/scripts/`: helper commands (see `modules/scripts/README.md`).
- `.plan/`: guide + status for the junior/agent; `.plan/docs/`: this directory.

## How a host is assembled

`flake.nix` (`mkHost`) → `hosts/<name>/default.nix` → `modules/` (loader). `mkHost` adds home-manager, forge modules and the overlays (`rust-overlay`, `self.overlays.default`). The CachyOS kernel overlay is the host option `modules.hardware.cachyos.enable` (off everywhere).

## Known impurities

- `chronos.url = "git+file:///home/jano/Proyectos/chronos"` and `classwork.url = "git+file:///home/jano/Proyectos/Classwork"`: absolute paths, break on other machines/CI. Owner decision pending.
- `modules/desktop/dotfiles.nix` links `~/.config/*` to the live checkout (`repoPath`), not the store, on purpose.
- The immaterial module seeds `~/.config/hypr` from the upstream dots copy-once (never overwrites).
