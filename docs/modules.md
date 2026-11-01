# Modules

Naming: local modules use `modules.<area>.*`; single-app wrappers (orchard, niXscout) keep `programs.<name>.enable` like nixpkgs. Areas: `core`, `hardware`, `theme` live under `profiles/base/`; capabilities live under `features/`. Each has a `default.nix` that only imports.

## `modules.desktop.*` (`modules/desktop/`)

| Option | File | Meaning |
|--------|------|---------|
| `session` (`mango`/`niri`/`hyprland`) | default.nix | compositor from the login screen |
| `shell` (`dynisland`/`chronos`/`halo`/`ii`/`immaterial`) | default.nix | Quickshell shell autostarted |
| `hyprlandMode` (`tablet`/`desktop`) | default.nix | first-login mode |
| `hyprlandTouch.enable` | default.nix | touch/tablet layer (halos1) |
| `greeterOsk.enable` | default.nix | on-screen keyboard in SDDM |
| `drmDevices` | features/hyprland-session/default.nix | DRM devices for Aquamarine |
| `ii.enable`, `ii.variant` (`p3drovfx`/`vynx`) | modules/desktop/shells/ii.nix | ii shell and which fork |
| `immaterial.enable` | features/immaterial/default.nix | immaterial-impulse shell (desktop/laptop) |
| `dotfiles.{enable,repoPath,host,dir,quickshell}` | features/dotfiles/default.nix | configs stored in the repo via symlinks |
| `autoMode` | features/halo/default.nix | tablet/desktop from keyboards |
| `haloGreeter.{enable,scale,user}` | features/greeter/greeter/greeter.nix | Halo greetd login |
| `haloSplash.enable` | features/greeter/splash.nix | Plymouth splash |
| `droidloom.{enable,user,sharedFolder,autoStart}` | features/droidloom/default.nix | Android apps |
| `mango.monitorRules` | modules/desktop/sessions/mango/mango.nix | legacy |

## Others

| Option | File |
|--------|------|
| `modules.programs.{profile,role,serverAddress}` | features/programs/default.nix (profile `full`/`lean`; deskflow role) |
| `modules.services.{sunshine,waydroid,powertop,smartd}.enable` | features/services-extras/default.nix |
| `hardware.nvidia.enable` | features/nvidia/default.nix |
| `programs.orchard.enable`, `programs.niXscout.enable` | features/{orchard,nixscout}/default.nix |

Generated reference (optional): `nixosOptionsDoc` filtered to `modules.*`.
