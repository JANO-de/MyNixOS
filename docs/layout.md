# Layout

Where things live. Everything is wired by explicit import lists (no auto-import).

```
flake.nix            inputs + outputs = import ./nix inputs
lib/mkHost.nix       host factory (home-manager, forge, overlays)
nix/                 default.nix (assembler), hosts.nix (host table), packages.nix, dev.nix
hosts/<host>/        default.nix + host-only files; dotfiles/ = app-written configs kept in git
modules/             core (always on), hardware, services, theme (modules.<area>.enable)
features/<name>/     one folder per capability (options + config), optional pkg/ and src/
pkgs/                packages shared by several features (hyprmon, matugen, localsend-cli)
scripts/             operational scripts (scripts/README.md)
docs/                this directory; beam-plan/ = agent guide + status
```

## Features

`features/default.nix` is the explicit import list. Hosts import `features/programs`,
`features/desktop`, `features` and `modules` (auto-loaded; hosts set `modules.<area>.enable`).

| Folder | What |
|--------|------|
| desktop | `modules.desktop.*` options: session, shell, SDDM, Wayland basics |
| hyprland-session | Hyprland (UWSM), Lua config, touch layer (`hyprland-touch.nix`) |
| greeter | SDDM theme, on-screen keyboard, Halo greetd greeter, Plymouth splash |
| halo, immaterial, dynisland, chronos | the shells (`modules.desktop.shell`); `halo/src`, `dynisland/src` hold the QML |
| dotfiles | `~/.config/{hypr,hyprmon,matugen}` linked into `hosts/<host>/dotfiles/` |
| droidloom | Android apps |
| nvidia | `hardware.nvidia.enable` |
| orchard, nixscout | app packages (`pkg/`) and their `programs.*.enable` |
| programs | profile `full` / `lean`, deskflow |
| services-extras | sunshine, waydroid, powertop, smartd |

## Add a feature

1. Create `features/<name>/default.nix` with a header: purpose, options, importer.
2. Add `./<name>` to `features/default.nix`.
3. Enable it from `hosts/<host>/default.nix`.
4. `git add -A` (flakes ignore untracked files), then `nix flake check` and build the hosts.

## Remove a feature

Delete its folder and its line in `features/default.nix`. Remove its flake input and run
`nix flake lock` (it prunes unused nodes). Compare the host `drvPath`s before and after.

## Rules

- A move changes paths only: the drvs must stay identical.
- Never edit `flake.lock` by hand; use `nix flake lock` / `nix flake update <input>`.
- Pin moving URLs by full `rev`.
