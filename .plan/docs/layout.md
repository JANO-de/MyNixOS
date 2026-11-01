# Layout

Where things live. The repo root holds `flake.nix`, `flake.lock`, `README.md`, `hosts/`, `modules/` and hidden files.

```
flake.nix        inputs + thin outputs (hosts = the folders in hosts/)
hosts/<host>/    default.nix = the host switchboard (modules.* flags) + hardware + host-only files;
                 dotfiles/ = app-written configs kept in git (never moved)
modules/         every capability, one module each; modules/default.nix is the only loader
.plan/           agent plan and docs (guide, status, docs/)
```

## modules/

| Folder | What |
|--------|------|
| core | boot, fonts, locale, nix, shell, users, home-manager (always on) |
| hardware | firmware, bluetooth, drives, nvidia, cachyos (`modules.hardware.enable` + one flag each) |
| services | audio, networking, printing, ssh, flatpak, sunshine, waydroid, powertop, smartd, qmk |
| theme | palette, GTK/Qt, alacritty, home (palette.nix is consumed by path) |
| desktop | session (SDDM, Wayland basics), hyprland-session, greeter, halo, immaterial, dynisland, chronos, dotfiles, droidloom |
| programs | profile `full` / `lean`, deskflow, orchard, nixscout |
| dev | `modules.dev.fullstack`, `modules.dev.java` (empty until the package lists arrive) |
| gaming | `modules.gaming.{steam,gamemode,all}` (empty until the package lists arrive) |
| scripts | one folder per helper command (`halo-dev`, `halos1-deploy`, ...); `modules.scripts.all` |
| pkgs | packages (hyprmon, matugen, localsend-cli) and the flake helpers (`default.nix`, `dev.nix`); not NixOS modules |

## Loader

`modules/default.nix` walks `modules/` recursively. A `*.nix` file is one module; a folder with its own
`default.nix` is one unit (that file imports its children). Folders named `pkg`, `src`, `dotfiles` and `pkgs`
are skipped (packages and sources, not NixOS modules). Every module is off until a host enables it.

## Add a module

1. Create `modules/<area>/<name>.nix` (or `<name>/default.nix` + `pkg/`, `src/`) with an option
   `modules.<area>.<name>` (`lib.mkEnableOption`) and the config behind `lib.mkIf`.
2. If the area folder has its own `default.nix`, add the file to its `imports`; otherwise the loader finds it.
3. Enable it from `hosts/<host>/default.nix`.
4. `git add` the files (flakes ignore untracked files), then `nix flake check` and build the hosts.

## Remove a module

Delete its file or folder (and its line in the area's `default.nix`, if any). Remove its flake input and run
`nix flake lock` (it prunes unused nodes). Compare the host `drvPath`s before and after.

## Rules

- A move changes paths only: the drvs must stay identical.
- Never edit `flake.lock` by hand; use `nix flake lock` / `nix flake update <input>`.
- Pin moving URLs by full `rev`.
