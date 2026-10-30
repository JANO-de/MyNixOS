# scripts/

One line per script (what, who runs it, where).

- `halo-dev.sh` — hot-reload loop for the Halo shell (no rebuild/reboot). Run on dev machine.
- `halo-ipc.sh` — talk to the halo-test shell on the Surface (`scripts/halo-ipc.sh call shade toggle`). Run on dev machine.
- `halo-live-binds.sh` — reset binds and add the top-edge shade bind. Run on dev machine.
- `halos1-android-apps.sh` — install F-Droid/Aurora/microG into Droidloom on halos1. Run on PC, targets halos1.
- `halos1-baseline.sh` — battery baseline measurement on halos1. Run on halos1 on battery.
- `halos1-clean.sh` — drop old Surface generations, rewrite boot menu. Run on halos1.
- `halos1-deploy.sh` — rebuild the Surface from this machine. Run on dev machine.
- `halos1-reboot.sh` — reboot the Surface. Run on dev machine.
- `suite-lint.py` — lint the Halo suite QML apps.
- `adopt-dotfiles.sh` — first-time import of `~/.config/{hypr,hyprmon,illogical-impulse,matugen}` into `dotfiles/<host>/` BEFORE the first rebuild with `dotfiles.enable`. Run on the target host.
- `migrate-dotfiles-per-host.sh` — move the legacy flat `dotfiles/` layout to `dotfiles/<host>/` (`--cleanup` removes the old copies). Run on the target host.
- `config-backup.sh` — back up / restore the mutable ii, Hyprland, hyprmon configs. Run on the target host.
- `ii-deps-check.sh` — audit ii runtime deps (binaries, python modules, fonts); prints only problems. Run on the target host.
