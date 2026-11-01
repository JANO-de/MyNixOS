# TODO

Legend: [ ] open · [~] in progress · [x] done · [?] waiting for owner
Finished work and task detail: `v2/STATUS.md`. This file: what is open, in order.

- [x] L-6 Docs and guide (31a3997)
- [x] L-7 Final verify: drvs equal to baseline, flake check and 3 builds pass, bash -n pass. nixfmt: 11 files unformatted, 10 untouched by L, `networking.nix` is a pure rename (R100)
- [ ] R-0..R-3 Cleanup: baseline, root and docs tree, comment and doc drift, thin `flake.nix`
- [ ] D-0..D-3 Delete: inventory, appOutlet-nix, Tokri leftovers, close
- [~] N-8, N-10, N-12, N-13 nixscout: third-party fetchers, detail pages, packaging, docs
- [ ] N-11 nixscout performance pass
- [?] M-0..M-9 Two-folder modules layout (`v2/M-modules.md`, plan written): starts after D and R-1; all ASK answered
- [ ] I-3b, I-4 Superseded by M5 `W`: close in `v2/STATUS.md` after owner OK

## Open questions for the owner
- R-1: ANSWERED (2026-11-01): delete `scripts/rename-halos1.sh` and `scripts/desktop-clear-oneshot.sh` (list shown before `git rm`, rule 14).
- R-3: `chronos` input (absolute path): keep, publish, or vendor? Remove unused inputs?
- N: app name (`nixscout` is a placeholder).
- Legacy removal: `features/dynisland`, `features/chronos`, `niri` in `hosts/halos1/tablet.nix`.
- halos1 shell (W-1b): ii test vs halo.


## Notes
- Owner runs `switch`/`test`/`sudo`. Beam only builds.
- Halo QML loop: `scripts/halo-dev.sh [halos1-ip]`.
