# M2: Delete appOutlet-nix and Tokri

Goal: no trace of either in the working tree. Git history keeps the past. Orchard stays.
Director's grep of the snapshot found these hits (re-check in D-0):

- appOutlet-nix: `pkgs/appoutlet-nix/`, `modules/programs/appoutlet.nix`, `docs/appoutlet-nix.md`, `beam-plan/02-appoutlet.md`, `notes/A-0.md`, `notes/A-1.md`, `notes/A-3.md`, `flake.nix` (4 blocks), `hosts/desktop/default.nix` (import + enable), `hosts/laptop/default.nix` (import + enable), `beam-plan/README.md`, `beam-plan/STATUS.md`, `prompt.md`.
- Tokri: `beam-plan/03-tokri-dynisland.md`, `notes/T-0.md`, `beam-plan/README.md`, `beam-plan/STATUS.md`, `prompt.md`. Shell code is already gone (STATUS says so); D-2 proves it.

## D-0 Inventory + baseline
**Do**
```
cd ~/Proyectos/MyNixOS && git switch -c beam/delete-legacy && git add -A
grep -rniE 'tokri|appoutlet' . --exclude-dir=.git --exclude=flake.lock
beam-plan/v2/drv-check.sh before
```
**Verify** hit list matches the one above; any extra file → add it to `notes/D-0.md` and delete it in the matching task.
**Done when** `notes/D-0.md` holds the final list and `/tmp/mynixos-drv-before.txt` exists.

## D-1 Remove appOutlet-nix
**Do**
1. Keep the verified source table for M1: `mkdir -p beam-plan/v2/notes && cp notes/A-3.md beam-plan/v2/notes/legacy-A-3.md`.
2. `git rm -r pkgs/appoutlet-nix modules/programs/appoutlet.nix docs/appoutlet-nix.md beam-plan/02-appoutlet.md notes/A-0.md notes/A-1.md notes/A-3.md`
3. `flake.nix`: delete `packages.x86_64-linux.appoutlet-nix` (+ its `let pkgs` block), `apps.x86_64-linux.appoutlet-nix`, the overlay line `appoutlet-nix = final.callPackage ...`, and `nixosModules.appoutlet`.
4. `hosts/desktop/default.nix` and `hosts/laptop/default.nix`: `grep -n appoutlet hosts/*/default.nix`, then remove the `modules/programs/appoutlet.nix` import line and the `programs.appoutlet.enable = true;` line in each.
5. Leave `rust-overlay` and everything Orchard.
**Verify**
```
grep -rniE 'appoutlet' . --exclude-dir=.git --exclude=flake.lock   # only beam-plan/v2 and STATUS history may match
nix flake check
beam-plan/v2/drv-check.sh after    # halos1 line unchanged; desktop and laptop lines MAY differ (they lose a package): confirm with the next line
nixos-rebuild dry-build --flake .#desktop && nixos-rebuild dry-build --flake .#laptop
```
**Done when** flake check passes, `halos1` drvPath is identical, desktop and laptop dry-build.

## D-2 Remove Tokri leftovers
**Do**
1. `git rm beam-plan/03-tokri-dynisland.md notes/T-0.md`
2. Delete the M3/Tokri row and Order mentions in `beam-plan/README.md`; delete the `## M3` section and the M2 section lines in `beam-plan/STATUS.md`; add one line `M2 AppOutlet-Nix, M3 Tokri: REMOVED by owner (2026-10-27)`.
3. `prompt.md`: delete the `//TODO.list` block (Orchard/AppOutlet/tokri lines, kickoff quote). Keep the persona rules above it.
**Verify**
```
grep -rniE 'tokri|basket' . --exclude-dir=.git --exclude=flake.lock
```
Any hit inside `modules/desktop/shell/dynisland/` → **ASK** (dynisland changes are one complete change per owner request). Elsewhere: remove.
**Done when** the grep is empty (except `beam-plan/v2/D-delete.md` and the one STATUS line).

## D-3 Close
**Do** `nix flake check`; `beam-plan/v2/drv-check.sh after`; update `beam-plan/v2/STATUS.md`; merge nothing (owner merges).
**Done when** report sent. Next: R-0 (or N-0).
