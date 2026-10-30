# Backlog (not scheduled; do nothing without the owner)

## Tablet (halos1, 4 GB): make ii run smoothly
- Path A, strip: disable heavy widgets/blur/animations and unused services through `config.json` flags.
- Path B, fork: minimal Quickshell config (bar, launcher, notifications, OSD) as a new package.
- Questions for the owner: which path; which widgets stay; accept no Matugen theming; RAM budget; keep touch gestures?
- Proof: boot halos1, record RAM/CPU; rollback = previous boot entry.

## Cleanup candidates (need ASK answers in STATUS)
- Remove mango session, dynisland shell, chronos session/shell and the `mango` input (A1).
- Impure local-path inputs `chronos`, `classwork` (A2).
- Drop the legacy flat `dotfiles/` layout after the desktop migration (owner actions in STATUS).
- Generate `docs/options.md` with `nixosOptionsDoc` filtered to `modules.*`.
- `modules/desktop/shell/halo-recolor-icons.py` sits next to the dynisland QML tree: move beside `shells/halo.nix` once halo.nix's path references are fixed in the same commit.
