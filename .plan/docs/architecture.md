# Architecture

## Tree

- `flake.nix`: inputs + `flake-parts.lib.mkFlake` with `imports = [ (import-tree ./parts) ]`.
- `parts/`: every flake-parts module (see `layout.md`). Features define `flake.nixosModules.*`; `parts/hosts/*.nix` also define `flake.nixosConfigurations.*`.
- `parts/lib.nix`: `flake.lib.mkHost` (the one place that builds a `nixosSystem`) and `flake.lib.commonModules`.
- `parts/packages.nix` + `pkgs/`: packages, apps and `flake.overlays.default`.
- `parts/dev.nix`: treefmt (nixfmt, statix, deadnix), the pre-commit hook, the dev shell and `checks`.
- `hosts/<host>/`: `hardware-configuration.nix` and `dotfiles/` (app-written configs kept in git).
- `.plan/docs/`: this directory.

## How a host is assembled

`parts/hosts/<name>.nix` defines two things:

1. `flake.nixosModules.host-<name>`: the host switchboard (`modules.*` flags, hostname, state version, host-only settings).
2. `flake.nixosConfigurations.<name> = self.lib.mkHost { modules = [ "host-<name>" ... ] ++ self.lib.commonModules; }`.

`mkHost` builds `nixosSystem` with `specialArgs = { inputs, theme }` and these modules, in order: home-manager, forge, niri-flake, noctalia, stylix, nix-gaming platform optimizations, then the host's module list (names resolve to `self.nixosModules.<name>`, duplicates removed), then an overlay module (`rust-overlay`, `self.overlays.default`).

`commonModules` is every option-gated feature module. Each is off until the host sets its `modules.*` option, so a host only lists extras that have no enable switch. The order matches the old loader so list-valued options merge the same way. The CachyOS kernel overlay is `modules.hardware.cachyos.enable` (off everywhere).

## Dev tooling

`nix fmt` runs treefmt with nixfmt, statix and deadnix (`--no-lambda-arg`, edits in place). The same wrapper is the pre-commit hook and the `checks.formatting` check.

## Known impurities

- `modules.desktop.dotfiles` links `~/.config/*` to the live checkout (`repoPath`), not the store, on purpose.
- `classwork` is commented out in `flake.nix` (absolute local path, breaks on other machines/CI).
- Service secrets are files on the host (`/var/lib/...`, `/root/...`), created empty by tmpfiles where the service needs them to exist.
