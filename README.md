# MyNixOS

Personal NixOS flake for three machines. Everything is a module, every module is **off until a host switches it on**.

| Host | Machine | Shell | Profile |
|------|---------|-------|---------|
| `desktop` | AMD + NVIDIA GTX 1060 | immaterial-impulse | full |
| `laptop` | Intel + NVIDIA RTX 3050 (PRIME offload) | immaterial-impulse | full |
| `halos1` | Surface Pro 5 (i5-7300U, 4 GB), tablet | Halo (own shell) | lean |

Stack: NixOS 26.05, Home Manager, Hyprland (UWSM, Lua config), Quickshell shells.

> This README is the map. Details live in [`.plan/`](.plan/README.md); each section below links to the page that owns it.

---

## Contents

1. [Quick start](#quick-start)
2. [Repo map](#repo-map)
3. [How it fits together](#how-it-fits-together)
4. [Hosts](#hosts)
5. [Modules](#modules)
6. [Shells](#shells)
7. [Commands](#commands)
8. [Dotfiles](#dotfiles)
9. [Flake inputs](#flake-inputs)
10. [Recipes](#recipes)
11. [Rules](#rules)
12. [The .plan folder](#the-plan-folder)

---

## Quick start

```bash
cd ~/Proyectos/MyNixOS
git add -A                                   # flakes only see tracked files
nix flake check
nixos-rebuild build --flake .#desktop        # or .#laptop / .#halos1
sudo nixos-rebuild switch --flake .#desktop  # you run this, never an agent
```

Rollback: pick the previous generation in the systemd-boot menu.
More: [`.plan/docs/workflow.md`](.plan/docs/workflow.md).

## Repo map

```
flake.nix        inputs + thin outputs (hosts = the folders in hosts/)
flake.lock       never edited by hand
hosts/<host>/    switchboard (default.nix) + hardware + host-only files
  dotfiles/      app-written configs kept in git (mango, ...)
modules/         every capability, one module each
.plan/           guide, status and docs (see below)
```

Full table: [`.plan/docs/layout.md`](.plan/docs/layout.md).

## How it fits together

```
flake.nix ──mkHost──▶ hosts/<host>/default.nix ──imports──▶ modules/default.nix (loader)
                              │                                      │
                      sets modules.* flags                walks modules/ and imports
                                                          every module it finds
```

- `mkHost` (in `flake.nix`) adds Home Manager, the forge module and the overlays (`rust-overlay`, `self.overlays.default`).
- **Loader** (`modules/default.nix`): a `*.nix` file is one module; a folder with its own `default.nix` is one unit (that file imports its children). Folders named `pkg`, `src`, `dotfiles`, `pkgs` hold packages and sources and are skipped.
- A new host is just a new folder in `hosts/`; the flake picks it up.

Details: [`.plan/docs/architecture.md`](.plan/docs/architecture.md).

## Hosts

A host file is a list of switches. Example shape (from `desktop`):

```nix
modules.hardware.enable = true;
modules.hardware.nvidia.enable = true;
modules.services.enable = true;
modules.theme.enable = true;
modules.programs.enable = true;
modules.desktop.enable = true;
modules.imi.enable = true;          # the shell
```

| Host | Notes |
|------|-------|
| `desktop` | Deskflow client, Sunshine server, data drives, Matrix (`matrix.nix`) |
| `laptop` | Deskflow server, PRIME offload, Sunshine |
| `halos1` | lean profile, tablet mode, touch layer, Halo greeter + splash, Droidloom, deployed from the PC over SSH, no hardware-configuration (disks by label) |

Details: [`.plan/docs/hosts.md`](.plan/docs/hosts.md), [`.plan/docs/halos1/`](.plan/docs/halos1).

## Modules

| Folder | Option namespace | Contents |
|--------|------------------|----------|
| `core` | always on | boot, nix, users, locale, fonts, shell, home-manager |
| `hardware` | `modules.hardware.*` | firmware, bluetooth, drives, `nvidia`, `cachyos` |
| `services` | `modules.services.*` | audio, networking, printing, ssh, flatpak, sunshine, waydroid, powertop, smartd, qmk |
| `theme` | `modules.theme.enable` | palette (plain data, passed to all modules as `theme`), GTK/Qt, Alacritty |
| `desktop` | `modules.desktop.*`, `modules.imi`, `modules.halo` | session, hyprland-session, greeter, halo, immaterial, dynisland, chronos, dotfiles, droidloom |
| `programs` | `modules.programs.*`, `programs.*` | profile `full`/`lean`, deskflow, orchard, niXscout |
| `dev` | `modules.dev.*` | `fullstack`, `java` (empty, waiting for package lists) |
| `gaming` | `modules.gaming.*` | `steam`, `gamemode`, `all` (empty, waiting for package lists) |
| `pkgs` | n/a | packages and flake helpers, not NixOS modules |

Every option, with its file: [`.plan/docs/modules.md`](.plan/docs/modules.md).

## Shells

| Shell | Switch | Hosts | Source |
|-------|--------|-------|--------|
| immaterial-impulse | `modules.imi.enable` | desktop, laptop | upstream flake input (not edited here) |
| Halo | `modules.halo.enable` | halos1 | `modules/desktop/halo/src/` (QML) |
| dynisland | `modules.desktop.shell = "dynisland"` | legacy | `modules/desktop/dynisland/` |
| chronos | `modules.desktop.shell = "chronos"` | legacy | `modules/desktop/chronos/` (input commented out) |

Halo suite style guide: [`.plan/docs/suite-style.md`](.plan/docs/suite-style.md).

## Dotfiles

`modules.desktop.dotfiles.enable` links `~/.config/mango` to `hosts/<host>/dotfiles/<name>` **in the live checkout** (not the Nix store), so edits apply without a rebuild and `git diff` shows every change.

## Flake inputs

nixpkgs `nixos-26.05`, home-manager, hyprland (no `follows`, keeps Cachix valid), hyprgrass, immaterial-impulse, zen-browser, opencode-flake, forge, claude-desktop, arcticons, rust-overlay, nixos-hardware, nix-cachyos-kernel (pinned). Policy per input: [`.plan/docs/inputs.md`](.plan/docs/inputs.md).

## Recipes

**Add a module**
1. Create `modules/<area>/<name>.nix` (or `<name>/default.nix`) with `options.modules.<area>.<name> = lib.mkEnableOption ...` and `config = lib.mkIf ...`.
2. If the area has its own `default.nix`, add the file to its `imports`.
3. Switch it on in `hosts/<host>/default.nix`.
4. `git add -A`, `nix flake check`, build the hosts.

**Remove a module**: delete the file or folder (and its `imports` line), drop its flake input, `nix flake lock`, compare drv paths.

**Prove a refactor changes nothing**: `.plan/v2/drv-check.sh before`, edit, `.plan/v2/drv-check.sh after` (prints `IDENTICAL`).

**Add a host**: new folder `hosts/<name>/default.nix` that imports `../../modules` and sets its flags.

## Rules

- A move changes paths only: derivations must stay identical.
- Flakes ignore untracked files: `git add -A` first.
- Never edit `flake.lock` by hand: `nix flake lock` / `nix flake update <input>`.
- Pin moving URLs by full `rev`.
- Known impurities: `chronos` and `classwork` point to local paths (see [architecture](.plan/docs/architecture.md)).

## The .plan folder

`.plan/` is the working brain of the repo: the rules the agent follows, the project status and the docs.

| Path | What |
|------|------|
| [`.plan/README.md`](.plan/README.md) | index of the plan |
| [`.plan/guidelines.md`](.plan/guidelines.md) | rules, repo facts, test loop, git flow |
| [`.plan/ask-first.md`](.plan/ask-first.md) | the questions asked before any step |
| [`.plan/todo.md`](.plan/todo.md) | open work and open questions |
| [`.plan/v2/STATUS.md`](.plan/v2/STATUS.md) | milestone checklist (M, L, W, R, ...) |
| [`.plan/v2/M-modules.md`](.plan/v2/M-modules.md) | the modules-layout plan this README describes |
| [`.plan/docs/`](.plan/docs/README.md) | the wiki pages: layout, architecture, hosts, modules, inputs, workflow, orchard, niXscout, suite-style |
| `.plan/docs/archive/`, `.plan/docs/roadmap/` | history and roadmap |

Where to look:

| Question | Page |
|----------|------|
| Where does X live? | [layout](.plan/docs/layout.md) |
| What option turns X on? | [modules](.plan/docs/modules.md) |
| How is a host built? | [architecture](.plan/docs/architecture.md) |
| What is each machine? | [hosts](.plan/docs/hosts.md) |
| Why this input / pin? | [inputs](.plan/docs/inputs.md) |
| How do I build, deploy, roll back? | [workflow](.plan/docs/workflow.md) |
| What is done, what is next? | [STATUS](.plan/v2/STATUS.md), [todo](.plan/todo.md) |
