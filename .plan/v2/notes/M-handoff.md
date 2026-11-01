# Handoff: M8 two-folder modules layout (2026-11-01)

Read first: `.plan/guidelines.md`, `todo.md`, `ask-first.md`, `v2/README.md`, then `v2/M-modules.md` (plan, all ASK answered) and `v2/notes/M-0.md` (host x option table, referrers).
This file does not replace the root `HANDOFF.md` (not available to the author; the owner said M does not need it).

## State
- D (delete legacy): closed, nothing left to delete (owner grep). R-1: done, e8734f7 (two one-shot scripts removed).
- M-0 recon: done. M-1 loader: delivered in halo-update-9, NOT yet verified by the owner.
- Branch: `beam/modules` (owner creates it before M-1). Commits so far on main: 20a92b2 (D-3), e8734f7 (R-1).

## Goal
Repo root = `flake.nix`, `flake.lock`, `README.md`, `hosts/`, `modules/`, hidden files (`.plan/` replaces `.plan/`, M-8). Every capability is a module with an `enable` option behind `lib.mkIf`, default false; each `hosts/<h>/default.nix` is the switchboard (`modules.imi.enable = true;`, `modules.dev.java = true;`, `modules.gaming.all = true;`). `modules/default.nix` auto-imports.

## Owner decisions (fixed)
- Rename everywhere, no aliases: `modules.imi.enable` replaces `shell = "immaterial"` + `immaterial.enable`; `modules.halo.enable` replaces `shell = "halo"`.
- Folder = option namespace: `modules/{core,hardware,services,theme,desktop,programs,dev,gaming,scripts,pkgs}`; `modules.programs.*` stays.
- Commands on PATH without `.sh` (`halo-dev`, `halos1-deploy`, `halos1-reboot`); bootstrap scripts also `nix run .#<name>`.
- Rule-13 paths may move (`features/halo/src/`, `shellDir`, the three scripts), referrers fixed in the same commit.
- `cachyos` flag = per-host option in `hosts/<h>/default.nix`. drv-hash churn from import order accepted only if `nix store diff-closures` shows no behaviour change.
- `dev.*`, `gaming.*` created empty until the owner sends package lists. `hosts/<h>/dotfiles/` does not move.
- Verify = `nixos-rebuild build --flake .#desktop` only (+ `drv-check.sh`, `nix flake check`). Laptop and halos1 are never built unless asked; say so in every report.

## Next, in order
1. Owner runs the M-1 block (drv-check before, extract halo-update-9, nixfmt, drv-check after, flake check, build desktop). Expect IDENTICAL x3. Then `git commit -m "M-1: modules loader"`.
2. M-2: `git mv profiles/base/{core,hardware,services,theme} modules/...` one commit each, add `enable` + `mkIf`, hosts set the flags, fix `nix/hosts.nix` palette path. Show the exact `git mv` list first (rule 14).
3. M-3 features one per commit (order in `M-modules.md`), M-4 pkgs, M-5 scripts, M-6 bundles, M-7 thin flake, M-8 docs/root (`beam-plan` -> `.plan`, delete root `dotfiles/` after listing), M-9 final verify.
Per task: ask first (question feature), `drv-check.sh before` at start / `after` at end, `nixfmt`, `bash -n`, one commit `M-n: <what>`, update `STATUS.md` + `todo.md`, deliver `halo-update-N.tar.gz` (changed files only, repo-relative paths; next N = 10).

## Gotchas
- Owner's shell aliases `grep` to `rg`: always `command grep` (`--exclude-dir` fails on rg).
- Never `git add -A`: `hosts/desktop/dotfiles/hypr/hyprland/colors.lua` is modified by the app and must stay out of commits. Add explicit paths.
- `/tmp/mynixos-drv-{before,after}.txt` can be root-owned (tee "Permiso denegado"): owner clears with `sudo rm -f`.
- `.kilo/worktrees/beam-plan/` is a second copy of the repo (state unknown: tracked/ignored?). Exclude it from greps. Owner has not yet sent `git check-ignore -v .kilo; git ls-files .kilo | head -3; git worktree list`.
- `features/nixscout/pkg/target/` (Rust build output) may be tracked: owner checks `git ls-files features/nixscout/pkg/target | head`; if tracked, untrack with a listed `git rm --cached`.
- Sandbox has no nix, no .git: Beam cannot run builds; give commands, ask for output.
- jq reducer used in M-0 drops `false`: `-` in the table means false.
- Loader skips folders `pkg`, `src`, `dotfiles`, `pkgs`; a folder with `default.nix` is one module.
- `hyprland-touch.nix:188` comment inside generated Lua changes the halos1 drv if edited (known from L-7).
- Referrers to fix per move are listed in `v2/notes/M-0.md` (hosts imports, `nix/{default,hosts,packages,dev}.nix`, `greeter.nix:12`, `halo-dev.sh:12`, `features/dynisland/default.nix:99`, `SetPageAndroid.qml:105`, script Usage lines, docs).

## Not tested (as of this file)
- `modules/default.nix` loader (never evaluated). Laptop and halos1 builds. Runtime of anything. Script wrappers (M-5 not started).

## Open
- Owner output of the M-1 block; output of the `.kilo` and `target/` checks.
- Legacy removal (`features/dynisland`, `features/chronos`, `niri` in `hosts/halos1/tablet.nix`) still unapproved; R-3 (`chronos` input) and N questions unchanged in `todo.md`.
