# Modules

Naming: local modules use `modules.<area>.*`; single-app wrappers (orchard, niXscout) keep `programs.<name>.enable` like nixpkgs. Areas: `core`, `services`, `programs`, `hardware`, `theme`, `desktop`. Each directory has a `default.nix` that only imports.

## `modules.desktop.*` (`modules/desktop/`)

| Option | File | Meaning |
|--------|------|---------|
| `session` (`mango`/`niri`/`hyprland`) | default.nix | compositor from the login screen |
| `shell` (`dynisland`/`chronos`/`halo`/`ii`) | default.nix | Quickshell shell autostarted |
| `hyprlandMode` (`tablet`/`desktop`) | default.nix | first-login mode |
| `hyprlandTouch.enable` | default.nix | touch/tablet layer (halos1) |
| `greeterOsk.enable` | default.nix | on-screen keyboard in SDDM |
| `drmDevices` | sessions/hyprland/hyprland.nix | DRM devices for Aquamarine |
| `ii.enable`, `ii.variant` (`p3drovfx`/`vynx`) | shells/ii.nix | ii shell and which fork |
| `dotfiles.{enable,repoPath,host,dir,quickshell}` | dotfiles.nix | configs stored in the repo via symlinks |
| `autoMode` | shells/halo.nix | tablet/desktop from keyboards |
| `haloGreeter.{enable,scale,user}` | greeter/greeter.nix | Halo greetd login |
| `haloSplash.enable` | splash.nix | Plymouth splash |
| `droidloom.{enable,user,sharedFolder,autoStart}` | droidloom.nix | Android apps |
| `mango.monitorRules` | sessions/mango/mango.nix | legacy |

## Others

| Option | File |
|--------|------|
| `modules.programs.{profile,role,serverAddress}` | programs/default.nix (profile `full`/`lean`; deskflow role) |
| `modules.services.{sunshine,waydroid,powertop,smartd}.enable` | services/extras.nix |
| `hardware.nvidia.enable` | hardware/nvidia.nix |
| `programs.orchard.enable`, `programs.niXscout.enable` | programs/ |

Generated reference (optional): `nixosOptionsDoc` filtered to `modules.*`.
