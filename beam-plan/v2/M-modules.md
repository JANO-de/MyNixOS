# M8: Two-folder modules layout

Status: PLAN ONLY. Nothing is moved by this document. Every task starts with the question feature (guidelines §0) and the ASK list below.

## Goal

Repo root holds `flake.nix`, `flake.lock`, `hosts/`, `modules/` and hidden files. Nothing else.
Every capability is a module with an `enable` option behind `lib.mkIf`, default `false`. A host's `default.nix` is its only switchboard:

```nix
modules.imi.enable = true;
modules.dev.fullstack = true;
modules.dev.java = true;
modules.gaming.all = true;
```

Human-readable, modular first, least complexity. Refactor is behaviour-neutral per task (rule 15).

## Target tree

```
MyNixOS/
├── flake.nix  flake.lock  README.md
├── .plan/                    agent plan and docs (today beam-plan/)
├── hosts/<h>/                default.nix (switchboard) + hardware + dotfiles/   (dotfiles/ does NOT move)
└── modules/
    ├── default.nix           the only loader (auto-import, see below)
    ├── core/                 today profiles/base/core: boot, fonts, locale, nix, shell, users, home-manager
    ├── hardware/             today profiles/base/hardware + features/nvidia
    ├── services/             today profiles/base/services + features/services-extras (sunshine, waydroid, powertop, smartd)
    ├── theme/                today profiles/base/theme (palette.nix is consumed by path)
    ├── desktop/              today features/{desktop,hyprland-session,greeter,halo,immaterial,dynisland,chronos,dotfiles,droidloom}
    ├── programs/             today features/{programs,orchard,nixscout}
    ├── dev/                  new: fullstack.nix, java.nix (contents ASK-7)
    ├── gaming/               new: steam.nix, gamemode.nix, all.nix (contents ASK-7)
    ├── scripts/              today scripts/ (one module per script, command on PATH)
    └── pkgs/                 today pkgs/ (packages, not NixOS modules)
```

## Conventions

1. Leaf module `modules/<area>/<name>.nix` or folder `modules/<area>/<name>/default.nix` (+ `pkg/`, `src/`, `dotfiles/`). Option `modules.<area>.<name>` is a boolean via `lib.mkEnableOption`; a module with settings becomes `modules.<area>.<name>.enable` + options.
2. Bundles (`all.nix`) set members with `lib.mkDefault true`, so a host can still turn one off.
3. Loader `modules/default.nix`: recursive `builtins.readDir`; imports every `*.nix` except `default.nix`, and a folder that has its own `default.nix` as one unit. It MUST skip directories named `pkg`, `src`, `dotfiles`, `pkgs` (their `default.nix` is not a NixOS module). UNVERIFIED until M-1 evals it.
4. Existing option names stay until the owner approves a rename (ASK-1). New names are added beside them.
5. `hosts/<h>/dotfiles/` stays where it is. `features/dotfiles` only reads `${repoPath}/hosts/${host}/dotfiles`, so no Home Manager link target changes and `~/.config/hypr` cannot dangle.
6. Host files keep hardware, identity, host-only modules (`matrix.nix`, `xampp.nix`, `tablet.nix`, `network-aula.nix`, `apps.nix`). Only the import list becomes `modules.*` flags.

## Risks (verified in the tarball)

- List-order churn: auto-import changes module order. List options (e.g. `environment.systemPackages`) can reorder, so a drv hash can change with identical behaviour. Rule 15 fallback: `nix store diff-closures`, explain every line (ASK-6).
- `scripts/halo-dev.sh` does `cd "$(dirname "$0")/.."` and rsyncs `features/halo/src/`. As a store script that breaks: the wrapper must `cd` to a configured repo path and use the new source path.
- Bootstrap scripts (`adopt-dotfiles.sh`, `migrate-dotfiles-per-host.sh`) must run BEFORE the rebuild that would install them. They also need a path-free entry (flake `apps`, ASK-2).
- Rule 13 paths touched (approved, ASK-3): `scripts/halo-dev.sh`, `halos1-deploy.sh`, `halos1-reboot.sh`, `features/halo/src/`, `shellDir` in `features/halo/default.nix`. `HANDOFF.md` is not in the tarball and the owner does not need it for M.
- `nix/default.nix` exports `nixosModules.orchard` and `nixosModules.niXscout` by path; `nix/packages.nix` has 3 callPackage path groups; `features/greeter/greeter/greeter.nix:12` and `features/nixscout/pkg/index.nix:9` use relative paths. All fixed in the same commit as their move.
- `hyprland-touch.nix:188` embeds a path comment in generated Lua: editing it changes the halos1 drv (known, L-7).
- Overlap: R-3 (thin flake) and D (legacy removal) touch the same files. Order fixed by the owner: D, then R-1, then M.

## Tasks

Per task: one commit `M-n: <what>` on branch `beam/modules`, `git add -A` first, `beam-plan/v2/drv-check.sh before` once at task start and `after` at the end, `nixfmt`, `bash -n`. Owner verification here: `nixos-rebuild build --flake .#desktop` only. Laptop and halos1 are NOT built unless the owner asks; every report says so.

**M-0 Recon.** Do: `git status` clean; map every `modules.*`/`programs.*` option per host with `nix eval` (host x option table) into `beam-plan/v2/notes/M-0.md`; list every referrer of each moved path (`grep -rn`). Verify: table covers desktop, laptop, halos1. Done when: ASK-1..8 answered.

**M-1 Loader.** Do: add `modules/default.nix` (convention 3) with no modules in it; import `../../modules` from the three hosts. Verify: `drv-check.sh after` IDENTICAL. Done when: loader evals and skips `pkg`/`src`.

**M-2 profiles/base to modules.** Do: `git mv profiles/base/core modules/core`, then hardware, services, theme (one commit each); remove the import line from each host; each file gets an `enable` option and `mkIf`; hosts set `modules.core.enable = true` etc. `nix/hosts.nix` theme path updated. Verify: build desktop + drv-check. Done when: `profiles/` is gone.

**M-3 features to modules, one per commit.** Order (small and independent first): services-extras, nvidia, programs, orchard, nixscout, droidloom, immaterial, dotfiles, greeter, hyprland-session, halo, dynisland, chronos, desktop. Do: `git mv`, fix relative paths, add `mkIf`/`enable` without renaming existing options, drop the line from `features/default.nix`. Update `nixosModules.*` exports and `nix/packages.nix` as each package moves. Verify: per commit. Done when: `features/` is gone.

**M-4 pkgs.** Do: `git mv pkgs modules/pkgs`; `nix/packages.nix` paths. Done when: `packages`, `apps`, overlay unchanged (`nix flake show`).

**M-5 scripts (rule 13, needs ASK-2 and ASK-3 answered).** Do: one module per script in `modules/scripts/<name>/` with the `.sh` beside a `default.nix` using `writeShellApplication`; wrapper sets repo path from `modules.scripts.repoPath` (default `/home/jano/Proyectos/MyNixOS`, same as dotfiles); enabled on the dev hosts only. Bootstrap scripts also exposed as flake `apps`. Fix every referrer (`scripts/README.md`, docs, `features/halo` comments). Verify: `bash -n` on each source; desktop builds; owner runs `halo-dev` once. Done when: `scripts/` is gone and the command names match the owner's answer.

**M-6 Bundles and switchboards.** Do: add `gaming/all.nix`, `dev/*.nix` empty (ASK-7: no package lists until the owner sends them); rewrite each `hosts/<h>/default.nix` import block into `modules.*` flags. Done when: the host files contain flags, not import paths to modules.

**M-7 Thin flake.** Do: fold `lib/mkHost.nix` and `nix/hosts.nix` into `flake.nix` (hosts from `readDir ./hosts`; the `cachyos` flag read from each host, ASK-5), `nix/dev.nix` and `nix/packages.nix` into `modules/pkgs` and `modules/dev` helpers or inline; delete `lib/`, `nix/`. Done when: `flake.nix` is under about 60 lines of outputs and `nix flake check` passes.

**M-8 Docs and root.** Do: `docs/`, `beam-plan/` per ASK-4; delete root `dotfiles/` (152 tracked legacy files): show the exact `git rm` list first (rule 14); update `docs/layout.md`, `docs/modules.md`. Done when: `ls` at root shows only `flake.nix`, `flake.lock`, `README.md`, `hosts`, `modules` plus hidden files.

**M-9 Final verify.** `nix flake check`; `nixos-rebuild build --flake .#desktop`; `nixfmt`; `bash -n`; stale-path grep for `features/`, `profiles/`, `scripts/`, `lib/`, `nix/`. Report what was not tested (laptop, halos1, runtime).

## Owner answers (2026-11-01)

1. ANSWERED (ASK-1): `modules.imi.enable` replaces `modules.desktop.shell = "immaterial"` and `modules.desktop.immaterial.enable`. Renamed everywhere, no aliases. Same rule for any later rename: hosts, docs and `docs/modules.md` change in the same commit.
2. ANSWERED (answered: ASK-2): command is `halo-dev` (no `.sh`); same for `halos1-deploy`, `halos1-reboot` and the other scripts. Bootstrap scripts (`adopt-dotfiles`, `migrate-dotfiles-per-host`) also as `nix run .#<name>`.
4. ANSWERED (ASK-4): hidden `.plan/` plus root `README.md`. `beam-plan/` becomes `.plan/`, so the typed path becomes `.plan/v2/drv-check.sh` (every referrer fixed in the same commit, M-8).
8. ANSWERED (ASK-8): finish D and R-1 first, then M. M-0 does not start before then.

3. ANSWERED (ASK-3): approved to move `features/halo/src/`, `shellDir`, `halo-dev`, `halos1-deploy`, `halos1-reboot`; every referrer fixed in the same commit. `HANDOFF.md` is not needed: not edited or delivered in M.
5. ANSWERED (ASK-5): the `cachyos` flag is a per-host option in `hosts/<h>/default.nix`; `flake.nix` reads it from there (M-7).
6. ANSWERED (ASK-6): drv-hash churn from import order is accepted only if `nix store diff-closures` shows no behaviour change; every line explained in the report.
7. ANSWERED (ASK-7): `dev.fullstack`, `dev.java`, `gaming.*` are created empty (option + `mkIf`, no packages); the owner sends the package lists later.

9. ANSWERED (ASK-9): folder = option namespace. `modules/programs/` and `modules.programs.*` stay (no `apps`).
10. ANSWERED (ASK-10): `modules.halo.enable` replaces `modules.desktop.shell = "halo"`, like `imi`. After both, `shell` only keeps the legacy `dynisland`/`chronos` values until their removal is approved.

## ASK (still open)

(none)
