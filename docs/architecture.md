# Architecture

## Tree

- `flake.nix` — inputs + outputs (delegated to `nix/`).
- `nix/` — `default.nix` (assembler), `hosts.nix` (mkHost + host table), `packages.nix` (orchard), `dev.nix` (devShell, formatter, checks).
- `hosts/{desktop,laptop,halos1}/` — per-host configuration.
- `modules/` — reusable NixOS modules (`core`, `services`, `programs`, `hardware`, `theme`, `desktop`).
- `pkgs/` — package definitions (orchard).
- `shell/halo/` — Halo QML shell (rsync source for halo-dev.sh).
- `scripts/` — operational scripts (see scripts/README.md).
- `assets/` — wallpapers.
- `docs/` — this directory.

## How a host is assembled

flake.nix → nix/hosts.nix (mkHost) → hosts/<name>/default.nix → modules (core, services, programs, hardware, desktop).

## Known impurities

- `chronos.url = "git+file:///home/jano/Proyectos/chronos"` (absolute path; breaks on other machines/CI). Owner decision pending (R-3 ASK).
