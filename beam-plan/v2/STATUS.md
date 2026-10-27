# STATUS v2 (Beam updates after every task)

Legend: [ ] todo · [~] in progress · [x] done · [!] blocked

## M2 Delete (D-delete.md)
- [ ] D-0 Inventory + baseline
- [ ] D-1 Remove appOutlet-nix
- [ ] D-2 Remove Tokri leftovers
- [ ] D-3 Close

## M3 Cleanup (R-cleanup.md)
- [ ] R-0 Baseline
- [ ] R-1 Root and docs tree
- [ ] R-2 Comment and doc drift
- [ ] R-3 Thin flake.nix
- [~] R-4 Modularize modules/
- [x] R-5 Scripts README
- [x] R-6 Documentation
- [x] R-7 Final proof

## M1 nixscout (N-nixscout.md)
- [x] N-0 Recon
- [ ] N-1 Source verification + Bazaar study
- [x] N-2 Dev shell + baseline
- [x] N-3 Schema
- [ ] N-4 Indexer: packages
- [ ] N-5 Indexer: options
- [ ] N-6 Indexer: modules
- [ ] N-7 Indexer: flakes
- [ ] N-8 Third-party fetchers
- [ ] N-9 UI shell
- [ ] N-10 Detail pages
- [ ] N-11 Performance pass
- [~] N-12 Packaging + integration (builds)
- [ ] N-13 Docs + owner checklist

## M4 ii-p3drovfx on Hyprland (I-ii.md)
- [x] I-0 Recon
- [ ] I-1 Package
- [~] I-2 Module (skeleton)
- [x] I-3a Layer the Hyprland config (halos1 byte-identical)
- [ ] I-3b Hyprland session on desktop + laptop (gate: owner accepts, then delete mango/dynisland?)
- [ ] I-4 Docs + update path

## Owner questions (ASK items)
- R-1: delete `scripts/rename-halos1.sh` and `scripts/desktop-clear-oneshot.sh`?
- R-3: `chronos` input (absolute path): keep, publish, or vendor? Remove unused inputs (list comes from R-0)?
- N: app name (`nixscout` is a placeholder).

## Blockers
(none)
