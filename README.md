# MyNixOS

Personal NixOS flake for two machines. Every feature is a module, and every module is **off until a host switches it on**.

| Host | Machine | Compositor | Shell | Profile |
|------|---------|------------|-------|---------|
| `desktop` | AMD + NVIDIA GTX 1060 | niri | Noctalia | full |
| `laptop` | Intel + NVIDIA RTX 3050 (PRIME offload) | niri | Noctalia | full |

Stack: NixOS 26.05, Home Manager, flake-parts + import-tree (dendritic layout), niri, Noctalia, Stylix.

> This README is the map. Details live in [`.plan/docs/`](.plan/docs/README.md); each section links to the page that owns it.

## Contents

1. [Quick start](#quick-start)
2. [Repo map](#repo-map)
3. [How it fits together](#how-it-fits-together)
4. [Hosts](#hosts)
5. [Modules](#modules)
6. [Dotfiles](#dotfiles)
7. [Flake inputs](#flake-inputs)
8. [Recipes](#recipes)
9. [Rules](#rules)
10. [The .plan folder](#the-plan-folder)

## Quick start

```bash
cd ~/Proyectos/MyNixOS
git add -A                  # flakes only see tracked files
nix fmt                     # nixfmt + statix + deadnix
nix flake check --no-build
nh os build                 # or: nh os switch
```

Rollback: pick the previous generation in the systemd-boot menu, or `nh os rollback`.
More: [`.plan/docs/workflow.md`](.plan/docs/workflow.md).

## Repo map

```
flake.nix        inputs + flake-parts entry (import-tree ./parts)
flake.lock       never edited by hand
parts/           every flake-parts module (dendritic): one file per feature, host or output
  hosts/         one file per host: its modules.* switches + its module list
  lib.nix        mkHost and commonModules (the modules every host gets)
  dev.nix        treefmt (nixfmt, statix, deadnix), pre-commit hook, dev shell, checks
  packages.nix   packages, apps, overlay
hosts/<host>/    hardware-configuration.nix + dotfiles/ (app-written configs kept in git)
pkgs/            package definitions (plain callPackage files) and the overlay
assets/          non-Nix files that modules read (flatpak bundle, cursors, tracker.py)
scripts/         helper scripts (drv-check.sh)
.plan/           docs and notes
```

Full table: [`.plan/docs/layout.md`](.plan/docs/layout.md).

## How it fits together

```
flake.nix ──import-tree──▶ parts/**.nix  (each defines flake.nixosModules.<name>)
                              │
     parts/hosts/<host>.nix ──mkHost──▶ nixosConfigurations.<host>
        sets modules.* flags, lists host-only modules, adds lib.commonModules
```

- `mkHost` (in `parts/lib.nix`) adds Home Manager, forge, niri-flake, Noctalia, Stylix, nix-gaming and the overlays (`rust-overlay`, `self.overlays.default`).
- **Dendritic**: every file under `parts/` is a flake-parts module found by `import-tree`; a feature is `flake.nixosModules.<area>-<name>`. Names starting with `_` are skipped.
- `lib.commonModules` lists the option-gated modules every host gets; a host lists only its own extras (modules with no enable switch).

Details: [`.plan/docs/architecture.md`](.plan/docs/architecture.md).

## Hosts

| Host | Notes |
|------|-------|
| `desktop` | Deskflow client, OpenRGB, data drives, the home server (`modules.server.enable`), backups, ntfy, AdGuard, Navidrome |
| `laptop` | Deskflow server, PRIME offload, Artcraft |

Details: [`.plan/docs/hosts.md`](.plan/docs/hosts.md).

## Modules

| Folder | Option namespace | Contents |
|--------|------------------|----------|
| `core` | always on | boot, nix, users, locale, fonts, shell, home-manager |
| `hardware` | `modules.hardware.*` | firmware, bluetooth, drives, `nvidia`, `cachyos`, `openrgb` |
| `services` | `modules.services.*` | audio, networking, printing, ssh, flatpak, waydroid, powertop, smartd, qmk, tailscale, virtualbox, backup |
| `server` | `modules.server.enable`, `modules.services.*` | the home-server services (Jellyfin, media stack, Kavita, Caddy, Homepage, ...) |
| `theme` | `modules.theme.enable` | palette (plain data, passed to all modules as `theme`), Stylix |
| `desktop` | `modules.desktop.*` | session, compositor (`niri`), shell (`noctalia`), dotfiles |
| `programs` | `modules.programs.*`, `programs.*` | profile `full`/`lean`, deskflow, apps, orchard, niXscout, TUIs |
| `dev` | `modules.dev.*` | `fullstack`, `java` |
| `gaming` | `modules.gaming.*` | `steam`, `gamemode`, `all` |

Every option, with its file: [`.plan/docs/modules.md`](.plan/docs/modules.md).

## Dotfiles

`modules.desktop.dotfiles.enable` links `~/.config/{kitty,niri,rofi}` to `hosts/<host>/dotfiles/<name>` **in the live checkout** (not the Nix store), so edits apply without a rebuild and `git diff` shows every change.

## Flake inputs

nixpkgs `nixos-26.05`, home-manager, stylix, niri-flake (pinned), noctalia, nix-gaming, nix-cachyos-kernel (pinned), rust-overlay, forge, zen-browser, opencode-flake, claude-desktop, flake-parts, import-tree, treefmt-nix, git-hooks and a few app sources. Policy per input: [`.plan/docs/inputs.md`](.plan/docs/inputs.md).

## Recipes

**Add a module**
1. Create `parts/<area>/<name>.nix` defining `flake.nixosModules.<area>-<name>` with `options.modules.<area>.<name>.enable = lib.mkEnableOption ...` and `config = lib.mkIf ...`.
2. Add `"<area>-<name>"` to `commonModules` in `parts/lib.nix` (or to one host's list if it has no enable switch).
3. Switch it on in `parts/hosts/<host>.nix`.
4. `git add -A`, `nix fmt`, `nix flake check --no-build`, build.

**Remove a module**: delete the file (and its name in `parts/lib.nix`), drop its flake input, `nix flake lock`, compare drv paths.

**Prove a refactor changes nothing**: `scripts/drv-check.sh before`, edit, `scripts/drv-check.sh after` (prints `IDENTICAL`).

**Add a host**: new `parts/hosts/<name>.nix` (copy desktop: a `host-<name>` module with the flags + `self.lib.mkHost`) and `hosts/<name>/hardware-configuration.nix`.

## Rules

- A move changes paths only: derivations must stay identical (source paths aside).
- Flakes ignore untracked files: `git add -A` first.
- `nix fmt` runs nixfmt, statix and deadnix with edits; the pre-commit hook and the `formatting` check enforce it.
- Never edit `flake.lock` by hand: `nix flake lock` / `nix flake update <input>`.
- Pin moving URLs by full `rev`.
- Secrets stay out of the repo: services read them from files on the host (`/var/lib/...`, `/root/...`).

## The .plan folder

Notes and docs live in [`.plan/`](.plan/README.md); open work is in [`todo.md`](todo.md). The wiki pages are indexed in [`.plan/docs/README.md`](.plan/docs/README.md).
