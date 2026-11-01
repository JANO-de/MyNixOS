# Workflow

- Build: `nixos-rebuild build --flake .#<host>` (never `switch` from an agent).
- Dry-build: `nixos-rebuild dry-build --flake .#<host>`
- Flake check: `nix flake check`
- Format: `nixfmt <file>` (CI check covers `flake.nix` and `modules/pkgs/*.nix`)
- Flakes only see tracked files: `git add -A` before any `nix` command.
- Behaviour-neutral proof: `.plan/v2/drv-check.sh before` ... edit ... `after`.
- Halo dev loop: `halo-dev`
- halos1 deploy / reboot: `halos1-deploy`, `halos1-reboot`
- Rollback: previous boot entry (systemd-boot menu).
