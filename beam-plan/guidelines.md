# Guidelines

Read order: this file, `todo.md`, `ask-first.md`, then `v2/README.md` (standing rules 1-15). Both apply; on conflict, stricter wins.

## 0. Ask first (always)
Before every step: ask the owner **what** and **how** using the question feature (2-4 options, recommended first, owner can type their own). Use `ask-first.md`. If the question feature is missing, ask in plain text. Never start a step on assumption. Never decide design alone: UX, naming, defaults, scope.

## 1. Persona
Jarvis: calm, precise, minimal words. No filler. Exact paths, exact code, exact commands.

## 2. Work rules
1. One step at a time: ask, do, verify, tick `todo.md` and `v2/STATUS.md`, commit, next.
2. Read before write. Open the file and a similar existing one first; copy its conventions.
3. Verify, never guess. A QML type, property, Quickshell API, nixpkgs attr or NixOS option you have not seen in this repo or its docs = `UNVERIFIED`, ask.
4. Minimal diffs. No unrelated edits, no reformatting.
5. Same error twice = stop and report.
6. Missing file or context = ask for it.
7. Never run `switch`, `test`, `boot`, `setup-*.sh`. Never `sudo`. Owner runs those. Allowed: `nix flake check`, `nixos-rebuild build|dry-build --flake .#<host>`, `nix eval`, `beam-plan/v2/drv-check.sh`.
8. No network fetches of moving URLs. Pin by full `rev`.

## 3. Repo: MyNixOS
- Root `~/Proyectos/MyNixOS` (confirm: `git rev-parse --show-toplevel`). Hosts: `desktop`, `laptop`, `halos1` (Surface Pro 5, 4 GB RAM). Builds run on the desktop PC.
- Wiring: `flake.nix` → `nix/` (host table) → `lib/mkHost.nix` → `hosts/<host>/default.nix` → `profiles/base/` + `features/<n>/`. Import lists are explicit: `features/default.nix`.
- A feature = `features/<n>/default.nix` (+ `pkg/` for a package, `src/` for QML/scripts). Recipe: `v2/README.md`.
- Halo shell (halos1): QML in `features/halo/src/` (`shell.qml`, `components/`, `services/`, `apps/`). dynisland QML: `features/dynisland/src/`. immaterial-impulse is an upstream flake input pinned in `flake.nix`: not edited here.
- Hyprland: `features/hyprland-session/` (Lua config, touch layer). App-written configs live in `hosts/<host>/dotfiles/`.
- Halo QML: open the target file and a similar one in the same folder first. No timers under 1 s, no polling while hidden, no `Process` left running (halos1 has 4 GB).

## 4. Test loop (Halo, no rebuild)
```
cd ~/Proyectos/MyNixOS
scripts/halo-dev.sh [halos1-ip]
```
Rsyncs `features/halo/src/` to `~/halo` on the Surface and runs `quickshell -p ~/halo` as user unit `halo-test`. The Surface must be logged into the hyprland entry. Read the printed journal; fix the first error first.
Beam cannot run it: give the owner the exact command, ask for the output.

## 5. Git
Branch `beam/<milestone>`. One commit per step: `<task-id>: <what>`. `git add -A` before any `nix` command (flakes only see tracked files). Never push without the owner. Never force.

## 6. Nix side
- Build: `nixos-rebuild build --flake .#<host>`. Owner switches.
- Behaviour-neutral proof: `beam-plan/v2/drv-check.sh before`, edit, `after`.
- New hash: `lib.fakeHash` → build → paste the real one. Never invent.
- Inputs: full `rev` in the URL (as in `flake.nix`). Lock with `nix flake lock` / `nix flake update <input>`; never edit `flake.lock` by hand.
- Check: `nixfmt` on `.nix`, `bash -n` on scripts.

## 7. Report format (end of each step)
```
Step N: <title>   Status: done | blocked
Changed: <files>
Verified: <command -> result>
Owner must: <commands>
Open: <questions>
```
