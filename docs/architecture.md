# Architecture

## Tree

- `flake.nix`: inputs + `outputs = import ./nix inputs`.
- `nix/`: `default.nix` (assembler), `hosts.nix` (`mkHost` + host table), `packages.nix` (packages, apps, overlay), `dev.nix` (devShell, formatter, checks).
- `hosts/{desktop,laptop,halos1}/`: per-host configuration (+ host-only modules: `matrix.nix`, `xampp.nix`, `tablet.nix`, ...).
- `modules/`: reusable NixOS modules: `core`, `services`, `programs`, `hardware`, `theme`, `desktop` (`sessions/`, `shells/`, `greeter/`, `dotfiles.nix`, `splash.nix`, `droidloom.nix`).
- `pkgs/`: package definitions: `orchard`, `niXscout`, `ii-p3drovfx`, `ii-vynx`, `ii-shapes.nix` (shared submodule pin), `hyprmon`, `matugen`, `localsend-cli`.
- `dotfiles/<host>/`: app-written configs kept in git (`hypr`, `hyprmon`, `illogical-impulse`, `matugen`). `dotfiles/` flat layout = legacy (desktop, until migrated).
- `shell/halo/`: Halo QML shell (rsync source of `scripts/halo-dev.sh`). `modules/desktop/shell/dynisland/`: legacy dynisland QML.
- `scripts/`: operational scripts (see `scripts/README.md`).
- `docs/`: this directory. `beam-plans/`: guide + status for the junior/agent.

## How a host is assembled

`flake.nix` → `nix/default.nix` → `nix/hosts.nix` (`mkHost`) → `hosts/<name>/default.nix` → `modules/*`.
`mkHost` adds home-manager, forge, mango modules and the overlays (`rust-overlay`, `self.overlays.default`).

## Known impurities

- `chronos.url = "git+file:///home/jano/Proyectos/chronos"` and `classwork.url = "git+file:///home/jano/Proyectos/Classwork"`: absolute paths, break on other machines/CI. Owner decision pending.
- `modules/desktop/dotfiles.nix` links `~/.config/*` to the live checkout (`repoPath`), not the store, on purpose.
- ii activation scripts seed `$HOME` copy-once (never overwrite). Rust helper build for p3drovfx needs network (crates.io).
