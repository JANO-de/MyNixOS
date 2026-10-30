# Workflow

- Build: `nixos-rebuild build --flake .#<host>` (never `switch` from an agent).
- Dry-build: `nixos-rebuild dry-build --flake .#<host>`
- Flake check: `nix flake check`
- Format: `nixfmt <file>` (CI check covers `flake.nix` and `nix/*.nix`)
- Flakes only see tracked files: `git add -A` before any `nix` command.
- Behaviour-neutral proof: `beam-plans/drv-check.sh before` ... edit ... `after`.
- Halo dev loop: `scripts/halo-dev.sh`
- halos1 deploy / reboot: `scripts/halos1-deploy.sh`, `scripts/halos1-reboot.sh`
- Rollback: previous boot entry (systemd-boot menu).
