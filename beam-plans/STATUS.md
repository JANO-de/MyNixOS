# STATUS (update after every task)

Legend: [ ] todo · [~] in progress · [x] done · [!] blocked
Snapshot: 2026-10-30. Nothing below was built by the director (no Nix in its sandbox): every `[~]` needs your build.

## Done (closed, no plan file kept)
- [x] Delete appOutlet-nix and Tokri (grep of the tree: no hits).
- [x] Repo cleanup: modular `modules/`, thin `flake.nix` + `nix/`, docs tree, scripts README. Old plans/notes/archive removed (2026-10-30). `.gitignore`, `.editorconfig` added.
- [x] ii-p3drovfx on Hyprland for `desktop` and `laptop` (module `modules/desktop/shells/ii.nix`, package `pkgs/ii-p3drovfx`).
- [x] Hyprland config layering (`hyprlandTouch.enable`, `@SESSION_EXTRAS@`).

## Active
- [~] **V** ii-vynx variant: code written, needs build and boot test. See `V-vynx.md`.
- [~] **N** niXscout: skeleton only (UI shell 124 lines, indexer, `data/*.json` are placeholders). See `N-niXscout.md`.

## Owner actions (from the old TODO.md)
- [ ] `scripts/migrate-dotfiles-per-host.sh desktop`
- [ ] delete the `modules.desktop.dotfiles.dir = ...` legacy line in `hosts/desktop/default.nix` (then the `mkForce` in `specialisation.vynx` can become `dotfiles.host = "desktop-vynx"`)
- [ ] `sudo nixos-rebuild switch --flake .#desktop`
- [ ] `scripts/migrate-dotfiles-per-host.sh --cleanup`

## Owner questions (ASK)
- A1: remove mango + dynisland + chronos session/shell code and the `mango` input? (desktop/laptop no longer use them; module defaults still do.)
- A2: `chronos` and `classwork` inputs use absolute local paths: keep, publish, or vendor?
- A3: `halos1` has `shell = "ii"` marked TEMPORARY. Keep testing, or go back to `halo`?
- A4: niXscout naming: code uses `niXscout` (`pkgs/niXscout`, `programs.niXscout`); old plans said `nixscout`. Keep `niXscout`?
- A5: after V-3, which ii fork becomes the default?

## Blockers
(none)
