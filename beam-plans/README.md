# Beam guide

Director: Claude · Executor: **Beam** (you) · Owner: user.
Repo: `~/Proyectos/MyNixOS` (confirm: `git rev-parse --show-toplevel`). Builds run on the desktop PC.
Hosts: `desktop`, `laptop`, `halos1` (Surface Pro 5, **4 GB RAM**: every MB counts).
This file is the single source of truth for how to work here. Read it fully, then `STATUS.md`, then the milestone file you are given.
Facts were checked on the owner's snapshot (2026-10-30). The real repo wins: re-verify before editing.

## 1. Files in this folder

| File | Purpose |
|------|---------|
| `README.md` | this guide (rules, map, recipes) |
| `STATUS.md` | what is done / open / waiting for the owner. Update after every task |
| `V-vynx.md` | milestone: ii-vynx variant (code in place, needs build + boot test) |
| `N-niXscout.md` | milestone: read-only Nix browser (skeleton exists) |
| `backlog.md` | ideas not scheduled (tablet strip, cleanup candidates) |
| `drv-check.sh` | behaviour-neutral proof (drvPath of all hosts) |
| `prompt.md` | persona/prompt used for interactive sessions |

Working notes go in `beam-plans/notes/<task-id>.md` (create the folder when needed). Delete notes when the task is closed and its facts live in `docs/`.

## 2. Repo map

```
flake.nix            inputs only (+ outputs = import ./nix inputs)
nix/                 default.nix assembler · hosts.nix (mkHost, host table) · packages.nix (packages/apps/overlay) · dev.nix (shell, formatter, checks)
hosts/<host>/        default.nix per host (+ host-only modules)
modules/             core · services · programs · hardware · theme · desktop (sessions/ shells/ greeter/ dotfiles.nix ...)
pkgs/                orchard · niXscout · ii-p3drovfx · ii-vynx · ii-shapes.nix · hyprmon · matugen · localsend-cli
dotfiles/<host>/     configs written by apps (hypr, hyprmon, illogical-impulse, matugen), kept in git
shell/halo/          Halo QML shell (rsync source of scripts/halo-dev.sh)
scripts/             operational scripts, one line each in scripts/README.md
docs/                reference docs (index: docs/README.md)
```

Option naming: `modules.<area>.*`; single-app wrappers use `programs.<name>.enable`.

## 3. Standing rules (non-negotiable)

1. **Read before write.** Note findings (`notes/<task-id>.md`) before coding.
2. **Verify, never guess.** Every URL, API, nixpkgs attr, NixOS option, crate feature: confirm with a command (`nix eval`, `curl -sI`, `--help`, reading source). Unconfirmed = write `UNVERIFIED` and ask.
3. **One task at a time.** Finish, verify, update `STATUS.md`, next.
4. **Build, never switch.** `nixos-rebuild build|dry-build --flake .#<host>`. `switch`, `test`, deploy scripts: owner only.
5. **Hashes:** `lib.fakeHash`, build, copy the real one. Never invent. Pin GitHub sources by full `rev`, never by branch or tag name.
6. **Pure builds.** The Nix sandbox has no network. Vendor with fixed-output fetchers (`fetchFromGitHub`, `fetchurl`, `cargoLock.lockFile`). Never fetch a moving URL (branch tarballs).
7. **Minimal diffs.** Match repo style, `nixfmt` (flake.nix, nix/*.nix are checked). No unrelated edits.
8. **Safe execution.** No `curl | sh`. Never run an upstream installer (`setup-*.sh`). No `sudo` in scripts. Argument arrays, not shell strings.
9. **Licences.** Keep upstream notices; `meta.license` truthful.
10. **Secrets.** No tokens in git. Read tokens from the environment only.
11. **Stop and ask** when: file/context missing; same error fails twice; destructive action not in the task; design choice not covered; scope creep. Items marked **ASK** always need the owner first.
12. **Git.** Branch `beam/<topic>`. One commit per task: `<task-id>: <what>`. `git add -A` before any `nix` command (flakes only see tracked files).
13. **Do not move or rename** (the owner types them): `shell/halo/`, `scripts/halo-dev.sh`, `scripts/halos1-deploy.sh`, `scripts/halos1-reboot.sh`, `HANDOFF.md`/`README.md`/`ROADMAP.md` at the repo root. A move needs owner approval and every referrer fixed in the same commit.
14. **List before deleting.** Show the exact `git rm` list in the report before running it, unless the task lists it.
15. **Behaviour-neutral proof.** Refactors: `beam-plans/drv-check.sh before` first, `after` last. Same drvPath = neutral. Different = `nix store diff-closures` old vs new, explain every line, or revert. A change meant to alter a host (new option used, new package) states which hosts must change and proves the others do not.
16. **halos1 is memory-bound.** Anything added to halos1 reports its closure size and idle RSS. `halos1` currently runs `shell = "ii"` as a temporary test (see STATUS); do not make that permanent and do not add heavy services to it.

## 4. Debug protocol

1. Reproduce with the exact command. 2. Read the FIRST failing line. 3. One hypothesis + the single variable that confirms it. 4. Check it (print, `nix eval`, `ls`, `--version`). 5. Smallest fix. 6. Rebuild. Two failed attempts on one error = stop and report.

## 5. Verification toolbox

```
git add -A
nix flake check
nix eval --raw .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
nixos-rebuild build --flake .#<host>                 # also builds specialisations
nix eval --raw .#nixosConfigurations.<host>.config.specialisation.vynx.configuration.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.<host>.config.modules.desktop.ii.variant
nix store diff-closures /nix/var/nix/profiles/system ./result
bash -n scripts/*.sh
```

Pin a GitHub source: `nix flake prefetch github:<owner>/<repo>/<rev> --json` (gives `hash`); or set `lib.fakeHash` and build.
Syntax-only check without Nix: parse with tree-sitter-nix (`pip install tree-sitter tree-sitter-language-pack`).

## 6. Recipes

### Add a package
1. `pkgs/<name>/default.nix` (header comment: what, upstream, how to update).
2. `nix/packages.nix`: add to the `let`, to `packages`, and to the `overlay` (all three).
3. If it needs a module: `modules/programs/<name>.nix` with `programs.<name>.enable` (+ `package`), import it from the host or `modules/programs/default.nix`.
4. `nix build .#<name>`, `nix flake check`, `drv-check.sh` (only the hosts that enable it may change).

### Add a module option
1. File under the matching area, header = purpose, options, importer.
2. Name `modules.<area>.<thing>.*`; `lib.mkEnableOption` for switches; enums for choices.
3. Add the row to `docs/modules.md`.
4. Default must keep every existing host's drvPath unchanged unless the task says otherwise.

### Add or change a host setting
Edit `hosts/<host>/default.nix` only. Shared behaviour goes into a module with an option, never copy-paste between hosts.

### Add another ii fork (pattern used for vynx)
1. Verify layout: `git clone --depth 1 --recurse-submodules <repo> /tmp/x`; check `dots/.config/{quickshell/ii,hypr,matugen}`, `.gitmodules`, `hypr/hyprland.lua` (Lua vs hyprland.conf), `execs.lua` (does it start `qs` itself?), python imports, Hyprland/Matugen version needs.
2. `pkgs/ii-<fork>/default.nix` modelled on `pkgs/ii-vynx/default.nix`; submodule via `pkgs/ii-shapes.nix` (add a new pin file if the commit differs).
3. `nix/packages.nix` (3 places), extend the `variant` enum in `modules/desktop/shells/ii.nix`, add the `pkgs.<name>` branch in `iiPkg`.
4. Separate state: `specialisation.<fork>` with its own `dotfiles.host` (or `dotfiles.dir = lib.mkForce ...` on hosts that set `dir`).
5. Document in `docs/ii.md`.

### Update a pinned fork (ii-p3drovfx, ii-vynx, ii-shapes)
`rev` to the new full commit, `hash = lib.fakeHash`, build, paste hash. Re-read the fork's `dots/.config/hypr/hyprland/execs.lua` and `variables.lua` for changes that the module patches (sed on `execs.lua`, thumbnail script, restart buttons). Build both hosts.

### Dotfiles (per-host app configs)
`modules.desktop.dotfiles.enable = true` links `~/.config/{hypr,hyprmon,illogical-impulse,matugen}` to `dotfiles/<host>/`. First time on a host: owner runs `scripts/adopt-dotfiles.sh --host <host>` before the rebuild. ii seeds defaults only into empty folders; it never overwrites. Never commit `preset-store/` or `hyprmon_backups/` (ignored in `.gitignore`).

## 7. Known pitfalls

- Flakes ignore untracked files: `git add -A` or the build "does not exist".
- `hyprland` input: never add `inputs.nixpkgs.follows` (Cachix cache dies). hyprctl and the portal must match the running compositor.
- ii needs Matugen >= 4.1.0 (`pkgs/matugen`, via the overlay) and quickshell >= 0.3.0. Hyprland >= 0.56 (Lua config).
- Nix indented strings (`''`): `${` interpolates, `''$` escapes, a lone `$` or `\` is literal. Test shell snippets with `bash -n` after extraction.
- `lib.optionalString` inside an activation script string needs its own `''...''` and correct indentation.
- ii copy-once logic: an existing `~/.config/quickshell/ii` is kept unless `.variant` differs. To force a re-seed delete the folder (owner).
- `modules.desktop.dotfiles.dir` set in a host + a specialisation that sets it again = conflict: use `lib.mkForce` in the specialisation.
- Home-manager activation runs on switch/boot of a generation. Specialisation + out-of-store symlinks was not tested end to end: report what you see in `journalctl -b -u home-manager-jano`.
- Never touch `flake.lock` by hand. `nix flake lock --update-input <name>` only, one input at a time, owner approves.

## 8. Task template

`ID` · Goal · Do · Verify (exact commands) · Done when.

## 9. Report format (after each task)

```
[ID] DONE|BLOCKED|NEEDS-INPUT
Changed: <files>
Verified: <command> -> <result tail, max 5 lines>
Next: <ID>
Question: <only if blocked>
```

## 10. Kickoff message

> Read `beam-plans/README.md` fully, then `STATUS.md`, then `<milestone>.md`. Start at the first open task. Follow the rules and report format exactly. Ask when blocked.
