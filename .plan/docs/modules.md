# Modules

Naming: local modules use `modules.<area>.<name>`; single-app wrappers (orchard, niXscout, ...) keep `programs.<name>.enable` like nixpkgs. Each module is a file `parts/<area>/<name>.nix` defining `flake.nixosModules.<area>-<name>`. `core` is always on; `hardware`, `services`, `theme`, `programs`, `desktop` and `server` have one `modules.<area>.enable` each, set by the host. The list below is a map; the authoritative list is `grep -rn 'options\.' parts`.

## `modules.desktop.*` (`parts/desktop/`)

| Option | File | Meaning |
|--------|------|---------|
| `enable` | session.nix | the desktop session (SDDM X11 greeter, Wayland session basics) |
| `compositor` (`niri`/`none`) | compositor.nix | installs niri (niri-flake, unstable) plus kitty and rofi |
| `shell` (`noctalia`/`none`) | shell.nix | Noctalia as a systemd user unit; needs a compositor |
| `dotfiles.{enable,repoPath,host,dir}` | dotfiles.nix | link `~/.config/{kitty,niri,rofi}` to `hosts/<host>/dotfiles/` in the live checkout |

## `modules.hardware.*` (`parts/hardware/`)

| Option | File | Meaning |
|--------|------|---------|
| `enable` | default.nix | firmware, bluetooth, drives and graphics basics |
| `nvidia.enable` | nvidia.nix | NVIDIA driver |
| `cachyos.enable` | cachyos.nix | CachyOS kernel overlay (pinned build; off on both hosts) |
| `openrgb.{enable,motherboard,defaultColor}` | openrgb.nix | OpenRGB server and the `rgb` on/off command |

## `modules.services.*` (`parts/services/`)

`enable` (default.nix) is the switch for the area. Per-service flags: `qmk`, `smartd`, `virtualbox`, `tailscale`, `waydroid`, `powertop`. Always-on when the area is enabled: audio, networking, printing, ssh, flatpak. Host-only modules (no flag): `services-backup`, `services-scrub`, `services-ntfy-alerts`, `services-wol`. `modules.artcraft.enable` (artcraft.nix) is the Artcraft launcher.

## Home server (`parts/server/`)

`modules.server.enable` (server.nix) switches the home-server group. Per-service options live under `modules.services.*`:

| Option | File |
|--------|------|
| `books`, `freshrss`, `homepage`, `itTools`, `openWebui`, `openwa`, `stirlingPdf`, `uptimeKuma`, `caddy` (`enable`) | one file each |
| `jellyfin.{enable,dataDir,cacheDir,mediaDir}` | jellyfin.nix |
| `kavita.{enable,port}` | kavita.nix |
| `mediaStack.{enable,mediaDir,downloadDir,qbittorrent.enable}` | media-stack.nix |
| `mediaTracker.{enable,mediaDir,trackerFile,user,...}` | media-tracker.nix |

Host-only modules (no flag): `server-vikunja`, `server-ntfy`, `server-adguard`, `server-navidrome`, `server-music-autotag`.

## `modules.programs.*` and `programs.*` (`parts/programs/`)

| Option | File | Meaning |
|--------|------|---------|
| `modules.programs.enable` | default.nix | the program sets |
| `modules.programs.profile` (`full`/`lean`) | default.nix | which set the host gets |
| `modules.programs.deskflow.{role,serverAddress}` | default.nix, deskflow.nix | keyboard/mouse sharing (`none`/`server`/`client`) |
| `modules.programs.{ai,apps,files,office,spotify}.enable` | one file each | everyday sets: local AI, apps, file tools, office, Spotify |
| `programs.{orchard,niXscout,nyaa-si,neo-mangal,vid-dl,ytm-player,ytm-rs,ytui,deviload}.enable` | one file each | single-app wrappers |

## Other

| Option | File | Meaning |
|--------|------|---------|
| `modules.theme.enable` | theme/default.nix | palette + GTK/Qt theming (Stylix is host-only: `theme-stylix`) |
| `modules.dev.{fullstack,java}.enable` | dev/ | development toolchains |
| `modules.gaming.{all,steam,gamemode}` | gaming.nix | Steam, GameMode; `all` turns on both |
