# ii shell (two forks)

Quickshell config for Hyprland. Enable:

```nix
modules.desktop.session = "hyprland";
modules.desktop.shell = "ii";
modules.desktop.ii.enable = true;
modules.desktop.ii.variant = "p3drovfx"; # or "vynx"
```

Forks: `P3DROVFX/ii-p3drovfx` (default) and `vaguesyntax/ii-vynx` (p3drovfx is a fork of vynx). Both come from end-4/dots-hyprland, ship `dots/.config/{quickshell/ii,hypr,matugen}`, use the Lua Hyprland config and start as `qs -c ii`. Neither has a flake or Nix packaging; **never run their `setup-*.sh`**.

## How it is wired

- `pkgs/ii-p3drovfx`, `pkgs/ii-vynx`: install the three trees under `$out/share/{quickshell/ii,hypr/ii,matugen/ii}`. `pkgs/ii-shapes.nix`: shared pin of the `rounded-polygon-qmljs` submodule.
- `modules/desktop/shells/ii.nix`: copies the trees into `$HOME` once (never overwrites), runs `qs -c ii` as the user unit `ii`, sets QML/Python/GI env.
- `modules/desktop/dotfiles.nix`: `~/.config/{hypr,hyprmon,illogical-impulse,matugen}` -> `dotfiles/<host>/`.
- `~/.config/quickshell/ii/.variant` records which fork the tree came from. Changing `ii.variant` re-seeds the tree on the next activation (a tree without the marker counts as p3drovfx).

## Try vynx (boot entry)

`desktop` and `laptop` have `specialisation.vynx`: vynx variant + separate dotfiles folder (`dotfiles/laptop-vynx/`, `dotfiles/desktop-vynx/`), so `config.json` and the Hyprland Lua of the two forks never mix.

```
nixos-rebuild build --flake .#laptop
sudo nixos-rebuild test --flake .#laptop --specialisation vynx   # owner only
```

Rollback: pick the default boot entry, or `nixos-rebuild test` without `--specialisation`.
Make vynx the default: set `modules.desktop.ii.variant = "vynx"` and `dotfiles.host` in the host file, delete the specialisation.

## vynx specifics

- vynx's `execs.lua` starts `qs` itself; the module deletes that line (the systemd unit does it).
- No Rust helpers, no hyprmon integration, no p3drovfx-only features (Nothing widgets, cheatsheet animations).
- Python `google` import exists in `services/gCloud/token-from-key-venv.sh` (optional feature); add `ps.google-auth` to `iiPython` if used.

## Update a fork

Bump `rev` in `pkgs/ii-<fork>/default.nix`, set `hash = lib.fakeHash`, build, paste the hash. If `.gitmodules` changed the shapes commit, update `pkgs/ii-shapes.nix`. Then `nixos-rebuild build` both hosts; re-check `scripts/ii-deps-check.sh` on the host.
