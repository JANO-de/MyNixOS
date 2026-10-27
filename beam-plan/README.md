# Beam Execution Plan

Director: Claude · Executor: Beam · Owner: user
Host OS: NixOS (flakes). Repo: `~/Documents/MyNixOS` (confirm: `git -C ~/Documents/MyNixOS rev-parse --show-toplevel`).

## Milestones

| ID | Upstream | Goal | Stack | Doc |
|----|----------|------|-------|-----|
| M1 | github.com/SFG5453/Orchard | Package + NixOS module | Qt6/QML, Rust, Meson, Node | `01-orchard.md` |
| M2 | github.com/AppOutlet/AppOutlet (archived, MIT) | Fork → Nix-native store with integrated nixpkgs / options / modules / flakes / 3rd-party flake search | Angular, Electron, TS | `02-appoutlet.md` |
| M3 | github.com/ysuraj1999/tokri | Reimplement as dynisland plugin | C++/Qt (source) → QML/Quickshell | `03-tokri-dynisland.md` |

Order: M1 → M2 → M3. M3 is independent and may start any time.
Decisions already made by the owner: M2 = fork the Electron app. M3 = reimplement in QML (no wrapping of the Qt binary). Targets = shared modules, enabled per host.

## Standing rules (non-negotiable)

1. **Read before write.** Inspect tree, build files, docs. Record findings in `notes/<task-id>.md` before coding.
2. **Verify, never guess.** Every URL, API, flag, nixpkgs attr, NixOS option, Quickshell/QML API: confirm with a command (`nix eval`, `nix search`, `curl -sI`, `--help`, reading source). Unconfirmed → write `UNVERIFIED` in notes and ask.
3. **One task at a time.** Finish → verify → update `STATUS.md` → next.
4. **Build, never switch.** Use `nixos-rebuild build|dry-build --flake .#<host>`. `switch` only on explicit owner approval.
5. **Hashes.** Use `lib.fakeHash`, build, copy the real hash from the error. Never invent one.
6. **Pure builds.** Nix sandbox has no network. Vendor all deps with fixed-output fetchers (cargo, npm/yarn, submodules).
7. **Minimal diffs.** Match existing MyNixOS style, format with `nixfmt`. No unrelated refactors.
8. **Safe execution.** No `curl | sh`. Spawn processes with argument arrays, never shell strings. No `sudo` inside scripts.
9. **Licences.** Keep upstream LICENSE files. Set `meta.license` truthfully (see M1 notes). Do not strip notices.
10. **Secrets.** Never commit tokens/cookies. Google sign-in happens only inside the app UI.
11. **Stop-and-ask triggers:** missing file or context; same error fails after 2 fix attempts; destructive/irreversible action; design choice not covered here; scope creep.
12. **Git.** Branch `beam/<milestone>`. One commit per task: `<task-id>: <what>`.

## Debug protocol (apply on every failure)

1. Reproduce with the exact command.
2. Read the FIRST failing line, not the last.
3. State hypothesis + the single variable that would confirm it.
4. Check that variable (print, eval, `ls`, `--version`).
5. Apply the smallest fix.
6. Rebuild. After 2 failed attempts on one error → stop and report.

## Task template (used in every milestone doc)

`ID` · Goal · Do · Verify (exact commands) · Done when.

## Report format (to owner, after each task)

```
[ID] DONE|BLOCKED|NEEDS-INPUT
Changed: <files>
Verified: <command> → <result tail, max 5 lines>
Next: <ID>
Question: <only if blocked>
```

## Global Definition of Done (per milestone)

- `nix flake check` passes.
- `nixos-rebuild build --flake .#surface` and `.#<desktop host>` succeed (confirm host names with `ls hosts/` or `nix flake show`).
- Module exposes `programs.<name>.enable`; enabled per host, not globally.
- Owner confirms GUI launches (Beam cannot verify visuals; provide a manual checklist).
- `docs/<name>.md` written (usage, options, known limits).
- `STATUS.md` updated.

## MyNixOS integration pattern

- Modules: `modules/programs/<name>.nix` (follow the existing `dev.nix` pattern) exposing `options.programs.<name>.enable`.
- Packages: `pkgs/<name>/default.nix`, exposed through an overlay or `callPackage` in the module.
- Hosts toggle: `programs.<name>.enable = true;` in each host file.
- Confirm all paths with `ls` first; if layout differs, adapt and note it.

## Kickoff message for Beam

> Read `README.md` fully, then `01-orchard.md`. Start at task O-0. Follow the rules and report format exactly. Ask when blocked.
