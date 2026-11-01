# STATUS v2 (Beam updates after every task)

Legend: [ ] todo · [~] in progress · [x] done · [!] blocked

## M2 Delete (D-delete.md)
- [x] D-0 Inventory + baseline (owner grep 2026-11-01: only .plan/docs/archive/beam-v1/STATUS.md:18 outside .kilo and beam-plan)
- [x] D-1 Remove appOutlet-nix (already gone: no tracked target)
- [x] D-2 Remove Tokri leftovers (already gone)
- [x] D-3 Close (no commit needed)

## M3 Cleanup (R-cleanup.md)
- [ ] R-0 Baseline
- [x] R-1 Root and docs tree (one-shot scripts removed, e8734f7; flake check passes; other table rows already done in L)
- [ ] R-2 Comment and doc drift
- [ ] R-3 Thin flake.nix
- [x] R-4 Modularize modules/
- [x] R-5 Scripts README
- [x] R-6 Documentation
- [x] R-7 Final proof

## M1 nixscout (N-nixscout.md)
- [x] N-0 Recon
- [x] N-1 Source verification (packages/options/registry verified)
- [x] N-2 Dev shell + baseline
- [x] N-3 Schema
- [x] N-4 Indexer: packages
- [x] N-5 Indexer: options
- [x] N-6 Indexer: modules
- [x] N-7 Indexer: flakes
- [~] N-8 Third-party fetchers (stubs)
- [x] N-9 UI shell (5-tab view switcher + search + paging)
- [~] N-10 Detail pages (list + search)
- [ ] N-11 Performance pass
- [~] N-12 Packaging + integration (builds)
- [~] N-13 Docs + owner checklist

## M4 ii-p3drovfx on Hyprland (I-ii.md)
- [x] I-0 Recon
- [x] I-1 Package (skeleton, fakeHash)
- [x] I-2 Module (skeleton)
- [x] I-3a Layer the Hyprland config (halos1 byte-identical)
- [ ] I-3b Hyprland session on desktop + laptop (gate: owner accepts, then delete mango/dynisland?)
- [ ] I-4 Docs + update path

## Owner questions (ASK items)
- R-1: DONE (e8734f7): deleted `scripts/rename-halos1.sh` and `scripts/desktop-clear-oneshot.sh`.
- R-3: `chronos` input (absolute path): keep, publish, or vendor? Remove unused inputs (list comes from R-0)?
- N: app name (`nixscout` is a placeholder).

## Blockers
(none)

## M5 immaterial-impulse on desktop + laptop (W)
- [x] W-0 Recon
- [x] W-1 List before deleting
- [x] W-2 Add flake input immaterial-impulse
- [x] W-3 Delete local folders
- [x] W-4 Wire immaterial-impulse to system (desktop+laptop)
- [x] W-5 Verify builds (desktop+laptop+halos1, flake check, nixfmt, bash -n)
- [x] W-6 Close (docs + W-immaterial.md)

## M6 feature-folder layout (L)
- [x] L-0 Recon + map
- [x] L-1 lib/ and nix/
- [x] L-2 profiles/base
- [x] L-3 features (one per commit)
- [x] L-4 dotfiles -> hosts/<h>/dotfiles
- [x] L-5 halo + dynisland sources
- [x] L-6 docs and guide
- [x] L-7 final verify
- Root cause: `qs` in PATH resolved to nixpkgs qs 0.3.2 (ABI mismatch with Qt 6.11); immaterial needs the upstream quickshell-wrapped.
- Fix: execs.lua now calls `/run/current-system/sw/bin/qs` (wrapped, added to systemPackages); laptop hypr migrated to upstream immaterial config (custom/ preserved); render_power clamped to 4.
- Verified: wrapped qs launches shell; desktop+laptop+halos1 build; flake check; nixfmt; bash -n.
- Owner verified: imi autostarts on launch (2026-11-01).

## M7 beam-plan docs refresh (B)
- [x] B-1 Rewrite guidelines/ask-first/README/todo for MyNixOS; archive v1 steps/roadmap/prompt-beam; fix v2/README facts

## M8 two-folder modules layout (M-modules.md)
- [x] M-plan Plan doc written (nothing moved)
- [x] M-0 Recon + option table (notes/M-0.md; ASK-9, 10 answered)
- [x] M-1 Loader (verified 2026-11-01: drv IDENTICAL x3, flake check, desktop build)
- [x] M-2 profiles/base to modules (bec7177, d00d8a7, 25f42bc, 5a2cd01; desktop built, laptop and halos1 not built; drv churn = udev rule order + home-manager-path order, explained)
- [x] M-3 features to modules (one per commit); shells: `modules.imi.enable`, `modules.halo.enable`; `modules.desktop.shell` legacy only
- [x] M-4 pkgs (modules/pkgs)
- [x] M-5 scripts (modules/scripts, `modules.scripts.all`)
- [x] M-6 Bundles and host switchboards (`modules.desktop.enable`, dev/gaming empty)
- [x] M-7 Thin flake (cachyos = `modules.hardware.cachyos.enable`)
- [x] M-8 Docs and root: docs moved to .plan/docs; root `dotfiles/` git rm pending owner OK (rule 14)
- [x] M-9 Final verify
- Order: D, then R-1, then M. ASK-1..8 all answered in `M-modules.md`.
