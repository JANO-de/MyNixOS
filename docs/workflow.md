# Workflow

- Build: `nixos-rebuild build --flake .#<host>`
- Dry-build: `nixos-rebuild dry-build --flake .#<host>`
- Flake check: `nix flake check`
- Format: `nixfmt <file>`
- Halo dev loop: `scripts/halo-dev.sh`
