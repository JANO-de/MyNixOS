# Ask first

Use the question feature (2-4 options, recommended first). Ask only what the task needs. One round, then work.

## Every task
1. Scope: do exactly the task / a subset / add something?
2. Approach: recommended way vs alternative (name the trade-off in one line).
3. Test: which command does the owner run, now or batched? (`halo-dev` for Halo QML; `nixos-rebuild build --flake .#<host>` for Nix)

## Per task type
- Delete or move: show the exact `git rm` / `git mv` list first (rule 14); ask about anything not listed.
- Halo QML: UX, naming, defaults, scope. Never decide alone.
- New feature folder: name, options, which hosts enable it.
- Input or pin change: full `rev` or tag? Who owns the repo?
- ASK items in `v2/STATUS.md` ("Owner questions") and in the task doc: answer first.

## Blockers
Missing file, `UNVERIFIED` item, error twice, design choice: stop and ask.
