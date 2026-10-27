# M3: Clean, modularize, document the flake

Goal: readable by a stranger in 10 minutes. One file = one concern. Docs first. **Zero behaviour change** (rule 15). Never `switch`.
No `.git` was in the snapshot: confirm with `git status` that the real repo is clean before starting.

## Findings (director, from the tarball; re-verify in R-0)

- **Root junk:** `x` (0 bytes), `HANDOFF-row-68.txt` (a HANDOFF row never merged), `info_drivers.txt` (laptop hardware dump, i5-11400H), `prompt.md`, `halos1-roadmap.svg.html`.
- **Working notes in the tree:** `beam-plan/` (v1), `notes/`.
- **Stale comments:** `modules/programs.nix` line 3 says `(surface)`; `modules/desktop/default.nix` header describes `surface: niri/chronos`; `hosts/halos1/default.nix` has a dead `sed -i '55s...'` hint, a stray `#ip routegit add -A && ...` line, and mentions `HYPRLAND_PLAN.md` (file does not exist; `modules/desktop/hyprland.nix` also mentions it); `flake.nix` has the CachyOS comment sitting above `nixos-hardware`.
- **flake.nix (152 lines)** mixes inputs, `mkHost`, per-package `import nixpkgs`, apps, overlay, modules.
- **Impure input:** `chronos.url = "git+file:///home/jano/Proyectos/chronos"` (absolute path; breaks on any other machine or CI).
- **Big mixed files:** `programs.nix` (159), `services.nix` (104), `core.nix` (99), `halo.nix` (230), `mango.nix` (221), `hyprland-touch.nix` (204), `extras/xampp.nix` (206).
- **Layout oddities:** QML trees live in two places (`shell/halo/` and `modules/desktop/shell/dynisland/`); host-only modules sit in `modules/extras/` (xampp, matrix); WM config files (`*.lua`, `niri.kdl`) sit loose beside `.nix`.
- **Scripts:** `halo-*` and `halos1-*` mixed; `rename-halos1.sh` and `desktop-clear-oneshot.sh` look one-shot.
- No `.gitignore`, no `.editorconfig`, no formatter/check outputs.

## R-0 Baseline
**Do**
```
git switch -c beam/cleanup && git add -A
beam-plan/v2/drv-check.sh before
nix flake check 2>&1 | tail -20
find . -path ./.git -prune -o -type f -print | sort > beam-plan/v2/notes/R-0-tree.txt
for i in $(nix eval --json .#inputs --apply builtins.attrNames | jq -r '.[]'); do printf '%s: ' "$i"; grep -rlw "$i" flake.nix hosts modules pkgs scripts | wc -l; done
```
**Output** `notes/R-0.md`: tree summary, which inputs have **no** use outside `flake.nix` (candidates for removal, never removed without owner OK), line counts per `.nix`, every `grep -rn "HYPRLAND_PLAN\|surface"` hit that is a comment (hardware names like `microsoft-surface-pro-intel`, `libwacom-surface` are correct, leave them).
**Done when** baseline file and notes exist.

## R-1 Root and docs tree (no code touched)
**Do** (`git mv`, list first, rule 14)

| From | To |
|------|----|
| `x` | delete |
| `HANDOFF-row-68.txt` | merge its row into the `HANDOFF.md` table after row 67, then delete |
| `info_drivers.txt` | `docs/hardware/laptop-info.txt` |
| `prompt.md` | `docs/dev/prompt.md` |
| `halos1-roadmap.svg.html` | `docs/roadmap/halos1-roadmap.svg.html` |
| `beam-plan/*.md` (v1) | `docs/archive/beam-v1/` |
| `notes/` | `docs/archive/notes/` |
| `scripts/ssh-config-halos1.txt` | `docs/halos1/ssh-config.txt` |
| `scripts/rename-halos1.sh`, `scripts/desktop-clear-oneshot.sh` | **ASK** (delete if the rename is deployed and the oneshot is obsolete) |

Stays at root: `README.md`, `ROADMAP.md`, `HANDOFF.md` (do not restructure it), `flake.nix`, `flake.lock`. Add `.gitignore` (`result`, `result-*`, `.direnv/`, `target/`, `*.qcow2`) and `.editorconfig`. `beam-plan/v2` moves to `docs/archive/` only when all milestones are done.
**Verify** `grep -rn 'info_drivers\|HANDOFF-row\|ssh-config-halos1\|prompt\.md' . --exclude-dir=.git` has no stale referrer; `drv-check.sh after` IDENTICAL.

## R-2 Comment and doc drift
**Do** fix every stale item in Findings (comments only). Every `.nix` file starts with a header: purpose, options it defines, who imports it (1-5 lines). Remove dead commented-out code; keep a comment only if it explains *why*.
**Verify** `drv-check.sh after` IDENTICAL (comments cannot change a drv).

## R-3 Thin `flake.nix`
**Do**
```
flake.nix        inputs (each with 1 comment: what, who uses it, follows policy) + outputs = import ./nix inputs
nix/default.nix  assembles outputs
nix/hosts.nix    mkHost + the host table (desktop, laptop, halos1)
nix/packages.nix per-system pkgs, packages, apps, overlays (orchard now, nixscout later)
nix/dev.nix      devShells (rust + gtk4/libadwaita for N), formatter, checks (nixfmt --check)
```
- Only `packages/apps/devShells/formatter` go through a `forAllSystems`; NixOS hosts stay `x86_64-linux`.
- Orchard keeps one `import nixpkgs` (with `rust-overlay`), not two.
- Unused inputs from R-0: list them to the owner. **ASK** before removing any.
- `chronos` impure path: **ASK** (keep as is, publish to a GitHub URL, or vendor). Until answered: leave it and document it in `docs/architecture.md` as a known impurity.
**Verify** `nix flake check`; `drv-check.sh after` IDENTICAL; `nix flake show` lists the same outputs as before (save the before output in R-0).

## R-4 Modularize `modules/` (one commit per step, drv-check after each)
Rule of thumb: >250 lines or >1 concern → split; two tiny files of one concern → merge; each directory gets a `default.nix` that only imports.
1. `modules/core.nix` → `modules/core/{boot,nix,users,locale,fonts,shell,home-manager}.nix`
2. `modules/services.nix` → `modules/services/{networking,audio,printing,ssh,flatpak,extras}.nix`
3. `modules/programs.nix` → `modules/programs/{default,lean,full,deskflow}.nix` (`orchard.nix` stays there)
4. `modules/hardware.nix` → `modules/hardware/{bluetooth,firmware,nvidia,drives}.nix`
5. `modules/home.nix` + `modules/theme.nix` → `modules/theme/{palette,gtk-qt,alacritty}.nix` (palette stays an attrset passed via `specialArgs`; do not change its shape)
6. `modules/desktop/` → `sessions/{hyprland,niri,mango}/` (each with its `.nix` **and** its `.lua`/`.kdl`; for Hyprland keep `hyprland.nix` (base) and `hyprland-touch.nix` (Surface/Halo touch layer) as **separate files** in that folder, never merge them: M4 gates them separately), `shells/{chronos,halo,dynisland}.nix`, `greeter/`, `splash.nix`, `droidloom.nix`
7. `modules/extras/xampp.nix` → `hosts/laptop/xampp.nix`; `matrix.nix` → `hosts/desktop/matrix.nix` (host-only)
8. dynisland QML: **do not move** (the owner may replace dynisland with ii in M4; decide after M4). `shell/halo/` does not move either.
- Option naming: local modules use `modules.<area>.*`; single-app wrappers (orchard, nixscout) keep `programs.<name>.enable` like nixpkgs. Write this in `docs/modules.md`.
- Large file with one concern (`halo.nix` 230, `mango.nix` 221): split only if a natural seam exists (service / scripts / options); otherwise leave and comment sections.
**Verify (each step)** `git add -A && beam-plan/v2/drv-check.sh after` IDENTICAL, else rule 15.

## R-5 Scripts
Do **not** move scripts (the owner types the names). Add `scripts/README.md`: one line per script (what, who runs it, where). `bash -n` every `.sh`. **Verify** `grep -rn 'scripts/' hosts modules flake.nix HANDOFF.md` paths all exist.

## R-6 Documentation
**Do** (short, accurate, linked from `README.md`)
- `docs/README.md` index.
- `docs/architecture.md`: tree with one line per directory, how a host is assembled (flake → `nix/hosts.nix` → host → modules), known impurities.
- `docs/hosts.md`: table per host (hardware, session, shell, profile, deploy command).
- `docs/modules.md`: naming convention + every `modules.*` option (name, type, default, file). Generate the reference with `nixosOptionsDoc` filtered to `modules.*`; commit the generated `docs/options.md` and the command that makes it.
- `docs/workflow.md`: build / deploy / rollback / halo-dev loop (only stable commands; do not copy HANDOFF's session-specific ones).
- `docs/inputs.md`: table of flake inputs.
- Root `README.md`: what it is, the new tree, three quick commands, links.
**Done when** every directory under `modules/` has a header in its `default.nix` and appears in `docs/architecture.md`.

## R-7 Final proof
```
git add -A && nix flake check
beam-plan/v2/drv-check.sh after
for h in desktop laptop halos1; do nixos-rebuild build --flake .#$h; done
bash -n scripts/*.sh
grep -rn 'modules/\(core\|services\|programs\|hardware\|home\|theme\)\.nix' . --exclude-dir=.git
```
Last grep must be empty. Differences in drvPath → rule 15 table in the report. Owner runs the deploy.
