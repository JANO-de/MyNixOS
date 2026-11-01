# Architecture

## Tree

- `flake.nix`: inputs + `outputs = import ./nix inputs`.
- `lib/`: `mkHost.nix` (host factory) + small helpers.
- `nix/`: `default.nix` (assembler), `hosts.nix` (host table), `packages.nix` (packages, apps, overlay), `dev.nix` (devShell, formatter, checks).
- `hosts/{desktop,laptop,halos1}/`: per-host configuration (+ host-only modules). `hosts/<host>/dotfiles/`: app-written configs kept in git.
- `profiles/base/`: always-on config (`core`, generic `hardware`, `services`, `theme`).
- `features/<name>/`: one folder per capability: `default.nix` (options+config), `pkg/`, `src/`. `features/default.nix` is the explicit import list.
- `pkgs/`: packages shared by several features (`hyprmon`, `matugen`, `localsend-cli`).
- `features/halo/src/`: Halo QML shell (rsync source of `scripts/halo-dev.sh`). `features/dynisland/src/`: dynisland QML.
- `scripts/`: operational scripts (see `scripts/README.md`).
- `docs/`: this directory. `beam-plan/`: guide + status for the junior/agent.

## How a host is assembled

`flake.nix` → `nix/default.nix` → `nix/hosts.nix` (`mkHost`) → `hosts/<name>/default.nix` → `profiles/base/*` + `features/*`.
`mkHost` adds home-manager, forge modules and the overlays (`rust-overlay`, `self.overlays.default`).

## Known impurities

- `chronos.url = "git+file:///home/jano/Proyectos/chronos"` and `classwork.url = "git+file:///home/jano/Proyectos/Classwork"`: absolute paths, break on other machines/CI. Owner decision pending.
- `features/dotfiles/default.nix` links `~/.config/*` to the live checkout (`repoPath`), not the store, on purpose.
- The immaterial module seeds `~/.config/hypr` from the upstream dots copy-once (never overwrites).
