# Workflow

- Flakes only see tracked files: `git add -A` before any `nix` command.
- Format and lint: `nix fmt` (nixfmt, statix, deadnix --edit). The pre-commit hook runs the same.
- Check: `nix flake check --no-build`
- Build: `nh os build` (or `nix build .#nixosConfigurations.<host>.config.system.build.toplevel --no-link`)
- Switch: `nh os switch`
- Behaviour-neutral proof: `scripts/drv-check.sh before`, edit, `scripts/drv-check.sh after` (prints IDENTICAL; source paths change drvs when files are added)
- Rollback: previous boot entry (systemd-boot menu) or `nh os rollback`
