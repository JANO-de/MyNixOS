# Orchard

YouTube Music client (Qt6/QML + Rust audio core). Packaged for MyNixOS as `pkgs/orchard`.

## Enable

```nix
programs.orchard.enable = true;
```

Enabled on `desktop` and `laptop` hosts. Requires `allowUnfree = true` (PolyForm Shield licence on adaptive-mix engine files).

## Options

- `programs.orchard.enable` — install Orchard.
- `programs.orchard.package` — package override (default `pkgs.orchard`).

## Known limits

- Adaptive mix requires a WebGPU-capable GPU; expected to fail on the Surface GPU. Documented limit, not blocker.
- Self-updater disabled (Nix store read-only); `ORCHARD_BOOTSTRAPPER`/`ORCHARD_INSTALL_ROOT` unset → `BootstrapperClient` inert.
- Google sign-in via WebEngine; test with default env first.
- Licence: AGPL-3.0-or-later + PolyForm Shield 1.0.0 (unfree).

## Update procedure

1. Bump `rev` in `pkgs/orchard/default.nix`.
2. Reset `hash` and `npmDepsHash`/cargo hashes to `lib.fakeHash`.
3. Rebuild; copy real hashes from errors.
4. Run `nix flake check` and `nixos-rebuild build --flake .#desktop`.
