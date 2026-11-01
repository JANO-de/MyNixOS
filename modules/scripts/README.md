# modules/scripts

One folder per helper command: `<name>.sh` (or `.py`) beside a `default.nix` (option `modules.scripts.<name>.enable`) and a `package.nix` (the command itself). The commands run from the repo checkout at `modules.scripts.repoPath` (default `/home/jano/Proyectos/MyNixOS`).

Enable everything on a dev host with `modules.scripts.all = true;`, or one command with `modules.scripts.<name>.enable = true;`.

| Command | What | Runs on |
|---------|------|---------|
| `halo-dev [ip]` | hot-reload loop for the Halo shell (no rebuild/reboot) | dev machine |
| `halo-ipc call shade toggle` | talk to the halo-test shell on the Surface | dev machine |
| `halo-live-binds` | reset binds, add the top-edge shade bind | dev machine |
| `halos1-deploy [ip]` | rebuild the Surface from this machine | dev machine |
| `halos1-reboot [ip]` | reboot the Surface | dev machine |
| `halos1-clean [ip]` | drop old Surface generations, rewrite the boot menu | dev machine |
| `halos1-android-apps [host]` | install F-Droid/Aurora/microG into Droidloom (piped over ssh) | dev machine |
| `halos1-baseline [s] [tag]` | battery baseline measurement | halos1, on battery |
| `suite-lint [apps_dir]` | lint the Halo suite QML apps (runs from the repo) | dev machine |
| `adopt-dotfiles` | first-time import of `~/.config` app configs into `hosts/<host>/dotfiles/`, BEFORE the first rebuild with `modules.desktop.dotfiles.enable`. Also `nix run .#adopt-dotfiles` | target host |
| `migrate-dotfiles-per-host` | legacy flat `dotfiles/` to `hosts/<host>/dotfiles/`. Also `nix run .#migrate-dotfiles-per-host` | target host |
| `config-backup backup\|restore [dir]` | back up / restore the mutable ii, Hyprland, hyprmon configs | target host |
