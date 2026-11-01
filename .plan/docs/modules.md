# Modules

Naming: local modules use `modules.<area>.<name>`; single-app wrappers (orchard, niXscout) keep `programs.<name>.enable` like nixpkgs. The folder is the option namespace: `modules/<area>/`. `core` is always on; `hardware`, `services`, `theme`, `programs`, `desktop` have one `modules.<area>.enable` each, set by the host.

## `modules.desktop.*` (`modules/desktop/`)

| Option | File | Meaning |
|--------|------|---------|
| `enable` | modules/desktop/session.nix | the desktop session (SDDM, Wayland basics, Hyprland through UWSM) |
| `session` (`hyprland`) | modules/desktop/session.nix | compositor from the login screen |
| `shell` (null/`dynisland`/`chronos`) | modules/desktop/session.nix | legacy Quickshell shells; the current ones have their own switch |
| `hyprlandMode` (`tablet`/`desktop`) | modules/desktop/session.nix | first-login mode |
| `hyprlandTouch.enable` | modules/desktop/session.nix | touch/tablet layer (halos1) |
| `greeterOsk.enable` | modules/desktop/session.nix | on-screen keyboard in SDDM |
| `drmDevices` | modules/desktop/hyprland-session/default.nix | DRM devices for Aquamarine |
| `dotfiles.{enable,repoPath,host,dir}` | modules/desktop/dotfiles.nix | configs stored in the repo via symlinks |
| `autoMode` | modules/desktop/halo/default.nix | tablet/desktop from keyboards |
| `haloGreeter.{enable,scale,user}` | modules/desktop/greeter/greeter/greeter.nix | Halo greetd login |
| `haloSplash.enable` | modules/desktop/greeter/splash.nix | Plymouth splash |
| `droidloom.{enable,user,sharedFolder,autoStart}` | modules/desktop/droidloom/default.nix | Android apps |

## Shells

| Option | File | Meaning |
|--------|------|---------|
| `modules.imi.enable` | modules/desktop/immaterial/default.nix | immaterial-impulse shell (desktop, laptop) |
| `modules.halo.enable` | modules/desktop/halo/default.nix | Halo shell (halos1) |

## Others

| Option | File |
|--------|------|
| `modules.programs.{enable,profile,deskflow.role,deskflow.serverAddress}` | modules/programs/default.nix (profile `full`/`lean`) |
| `programs.orchard.enable`, `programs.niXscout.enable` | modules/programs/{orchard,nixscout}/default.nix |
| `modules.services.{enable,sunshine,waydroid,powertop,smartd,qmk}` | modules/services/ |
| `modules.hardware.{enable,nvidia.enable,cachyos.enable}` | modules/hardware/ |
| `modules.theme.enable` | modules/theme/default.nix |
| `modules.dev.{fullstack,java}`, `modules.gaming.{steam,gamemode,all}` | modules/dev/, modules/gaming/ (empty) |
| `modules.scripts.{all,repoPath,<name>.enable}` | modules/scripts/ |

Generated reference (optional): `nixosOptionsDoc` filtered to `modules.*`.
