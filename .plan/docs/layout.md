# Layout

Where things live. The repo root holds `flake.nix`, `flake.lock`, `README.md`, `todo.md` and the folders below.

```
flake.nix        inputs + flake-parts entry (import-tree ./parts)
parts/           every flake-parts module: features, hosts, packages, dev tooling
hosts/<host>/    hardware-configuration.nix + dotfiles/ (app-written configs kept in git)
pkgs/            package definitions (callPackage files) + overlay.nix
assets/          non-Nix files modules read (flatpak bundle, cursors, tracker.py)
scripts/         helper scripts (drv-check.sh)
.plan/           docs and notes
```

## parts/

| Path | What |
|------|------|
| `core/` | boot, fonts, home-manager, locale, nix, shell, users (always on) |
| `hardware/` | firmware, bluetooth, drives, nvidia, cachyos, openrgb (`modules.hardware.enable` + one flag each) |
| `services/` | audio, networking, printing, ssh, flatpak, waydroid, powertop, smartd, qmk, tailscale, virtualbox, backup, scrub, ntfy-alerts, wol, artcraft |
| `server/` | home-server services: adguard, books, caddy, freshrss, homepage, it-tools, jellyfin, kavita, media-stack, media-tracker, navidrome, ntfy, open-webui, openwa, stirling-pdf, uptime-kuma, vikunja |
| `theme/` | `default.nix`, `stylix.nix`; `_palette.nix` is plain data (skipped by import-tree, passed to modules as `theme`) |
| `desktop/` | session (SDDM, Wayland basics), compositor (niri), shell (Noctalia), dotfiles |
| `programs/` | profile `full`/`lean`, deskflow, apps, office, files, ai, spotify, orchard, niXscout, TUIs |
| `dev/` | `fullstack`, `java` |
| `gaming.nix` | `modules.gaming.{steam,gamemode,all}` |
| `hosts/` | one file per host |
| `lib.nix` | `mkHost` and `commonModules` |
| `packages.nix` | packages, apps, overlay |
| `dev.nix` | treefmt, pre-commit hook, dev shell, checks |

## How modules are found

`flake.nix` calls `import-tree ./parts`: every `*.nix` file below `parts/` is a flake-parts module. Files and folders whose name starts with `_` are skipped. A feature file defines `flake.nixosModules.<area>-<name>`; a host builds its system from module names (`self.lib.mkHost`).

## Add a module

1. Create `parts/<area>/<name>.nix`:

   ```nix
   _: {
     flake.nixosModules.<area>-<name> =
       { config, lib, pkgs, ... }:
       let
         cfg = config.modules.<area>.<name>;
       in
       {
         options.modules.<area>.<name>.enable = lib.mkEnableOption "...";
         config = lib.mkIf cfg.enable { /* ... */ };
       };
   }
   ```

2. A module with an enable switch goes into `commonModules` in `parts/lib.nix` (every host gets it, off by default). A module without a switch is listed in the host file that wants it (see `server-vikunja` in `parts/hosts/desktop.nix`).
3. Enable it in `parts/hosts/<host>.nix`.
4. `git add -A`, `nix fmt`, `nix flake check --no-build`, build the hosts.

## Remove a module

Delete its file and its name in `parts/lib.nix` (or the host list). Remove its flake input and run `nix flake lock` (it prunes unused nodes). Compare the host `drvPath`s with `scripts/drv-check.sh`.

## Rules

- Never edit `flake.lock` by hand; use `nix flake lock` / `nix flake update <input>`.
- Pin moving URLs by full `rev`.
- Non-Nix files go in `assets/`; package sources in `pkgs/<name>/`.
