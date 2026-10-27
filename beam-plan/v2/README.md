# Beam Plan v2

Director: Claude · Executor: Beam · Owner: user
Repo: `~/Proyectos/MyNixOS` (confirm: `git rev-parse --show-toplevel`). Builds run on the desktop PC.
Targets: `desktop`, `laptop`, `halos1` (Surface Pro 5, **4 GB RAM**: every MB counts).
Facts below were checked by the director on the owner's tarball (2026-10-27) with `grep`/`ls`. Real repo wins: re-verify before editing.

## Milestones

| ID | Goal | Doc |
|----|------|-----|
| M2 `D` | Delete appOutlet-nix and Tokri leftovers | `D-delete.md` |
| M3 `R` | Clean, modularize, document the flake repo | `R-cleanup.md` |
| M4 `I` | ii-p3drovfx shell on Hyprland, replacing mango on desktop + laptop (never halos1) | `I-ii.md` |
| M1 `N` | `nixscout`: Bazaar-style read-only browser (packages, options, modules, flakes, third-party flakes) | `N-nixscout.md` |

Order: **D first** (small; keeps later diffs clean). Then N and R are independent. N-0..N-11 touch only `pkgs/nixscout/` and `beam-plan/v2/notes/`. N-12 edits `flake.nix`: do it **after R-3**. M4 `I` runs **after R-4** (module layout final).

## Owner decisions (fixed)

- Orchard stays (not in scope).
- Desktop and laptop move from mango to Hyprland + ii (M4). mango and dynisland are removed only after the owner accepts ii.
- nixscout is **read-only**: it never installs, removes or runs Nix. Copy-to-clipboard buttons are allowed.
- nixscout = Rust + GTK4/libadwaita (same toolkit as Bazaar). No Electron, no webview, no async runtime.
- Refactor is behaviour-neutral. Paths the owner types stay valid (rule 13).

## Standing rules (non-negotiable)

1. **Read before write.** Record findings in `beam-plan/v2/notes/<task-id>.md` before coding.
2. **Verify, never guess.** Every URL, API, nixpkgs attr, NixOS option, crate feature, GTK/libadwaita API: confirm with a command (`nix eval`, `curl -sI`, `--help`, `pkg-config --modversion`, reading source). Unconfirmed → write `UNVERIFIED` in notes and ask.
3. **One task at a time.** Finish → verify → update `STATUS.md` → next.
4. **Build, never switch.** `nixos-rebuild build|dry-build --flake .#<host>`. `switch`/deploy only by the owner.
5. **Hashes:** `lib.fakeHash`, build, copy the real one. Never invent.
6. **Pure builds.** The Nix sandbox has no network. Vendor everything with fixed-output fetchers (`cargoLock.lockFile`, `fetchurl` with hash).
7. **Minimal diffs.** Match repo style, format with `nixfmt`. No unrelated edits.
8. **Safe execution.** No `curl | sh`. Argument arrays, never shell strings. No `sudo` in scripts.
9. **Licences.** Keep upstream notices; `meta.license` truthful.
10. **Secrets.** No tokens committed. `GITHUB_TOKEN` is read from the environment only, never stored.
11. **Stop and ask** when: file/context missing; same error fails twice; destructive action not listed in the task; design choice not covered; scope creep. Items marked **ASK** always need the owner's answer first.
12. **Git.** Branch `beam/<milestone>`. One commit per task: `<task-id>: <what>`. `git add -A` before any `nix` command (flakes only see tracked files).
13. **Do not break these paths** (the owner types them; HANDOFF.md §0c quotes them): `shell/halo/` (rsync source of `scripts/halo-dev.sh`, `shellDir` in `modules/desktop/shell/halo.nix`), `scripts/halo-dev.sh`, `scripts/halos1-deploy.sh`, `scripts/halos1-reboot.sh`, `HANDOFF.md` at repo root. Moving any of them needs owner approval and every referrer fixed in the same commit.
14. **List before deleting.** Show the exact `git rm` list in the task report before running it, unless the task already lists it.
15. **Behaviour-neutral proof.** `beam-plan/v2/drv-check.sh before` once at the start of a task, `after` at the end. Same `drvPath` = proven neutral. Different = run `nix store diff-closures` between old and new toplevel, explain every line, or revert.

## Debug protocol

1. Reproduce with the exact command. 2. Read the FIRST failing line. 3. State one hypothesis + the single variable that confirms it. 4. Check it (print, eval, `ls`, `--version`). 5. Smallest fix. 6. Rebuild. Two failed attempts on one error → stop and report.

## Task template

`ID` · Goal · Do · Verify (exact commands) · Done when.

## Report format (after each task)

```
[ID] DONE|BLOCKED|NEEDS-INPUT
Changed: <files>
Verified: <command> → <result tail, max 5 lines>
Next: <ID>
Question: <only if blocked>
```

## Kickoff message for Beam

> Read `beam-plan/v2/README.md` fully, then `D-delete.md`. Start at task D-0. Follow the rules and report format exactly. Ask when blocked.
