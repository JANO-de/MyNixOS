# Modules

Naming: local modules use `modules.<area>.*`; single-app wrappers (orchard, niXscout) keep `programs.<name>.enable` like nixpkgs. Areas: `core`, `hardware`, `services`, `theme` live under `modules/` (`core` always on, the others behind `modules.<area>.enable`); capabilities live under `features/`. Each has a `default.nix` (imports, plus the `enable` option except in `core`).

## `modules.desktop.*` (`features/desktop/` and the features below)

| Option | File | Meaning |
|--------|------|---------|
| `session` (`hyprland`) | features/desktop/default.nix | compositor from the login screen |
| `shell` (`dynisland`/`chronos`/`halo`/`immaterial`) | features/desktop/default.nix | Quickshell shell autostarted |
| `hyprlandMode` (`tablet`/`desktop`) | features/desktop/default.nix | first-login mode |
| `hyprlandTouch.enable` | features/desktop/default.nix | touch/tablet layer (halos1) |
| `greeterOsk.enable` | features/desktop/default.nix | on-screen keyboard in SDDM |
| `drmDevices` | features/hyprland-session/default.nix | DRM devices for Aquamarine |
| `immaterial.enable` | features/immaterial/default.nix | immaterial-impulse shell (desktop/laptop) |
| `dotfiles.{enable,repoPath,host,dir}` | features/dotfiles/default.nix | configs stored in the repo via symlinks |
| `autoMode` | features/halo/default.nix | tablet/desktop from keyboards |
| `haloGreeter.{enable,scale,user}` | features/greeter/greeter/greeter.nix | Halo greetd login |
| `haloSplash.enable` | features/greeter/splash.nix | Plymouth splash |
| `droidloom.{enable,user,sharedFolder,autoStart}` | features/droidloom/default.nix | Android apps |

## Others

| Option | File |
|--------|------|
| `modules.programs.{enable,profile,role,serverAddress}` | modules/programs/default.nix (profile `full`/`lean`; deskflow role) |
| `modules.services.{sunshine,waydroid,powertop,smartd,qmk}.enable` | modules/services/{sunshine,waydroid,powertop,smartd,qmk}.nix |
| `modules.hardware.nvidia.enable` | modules/hardware/nvidia.nix |
| `programs.orchard.enable`, `programs.niXscout.enable` | features/{orchard,nixscout}/default.nix |

Generated reference (optional): `nixosOptionsDoc` filtered to `modules.*`.
