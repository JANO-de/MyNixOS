# M2 — AppOutlet → Nix-native store

Upstream: `https://github.com/AppOutlet/AppOutlet` — **archived 2023-10-25**, MIT, Angular + Electron + TypeScript, yarn, Jest. Originally supports AppImage/Flatpak/Snap. Repo layout: `core/`, `src/`, `e2e/`, `main.js`, `preload.js`, `electron-builder.json`, `angular.json`, `yarn.lock`.

Decision (owner): **fork the Electron app**, retarget to Nix. No upstream sync exists; this is a hard fork. Keep MIT licence + original copyright, add own line.

Target product: one window, five search tabs over a unified index:
**Packages (nixpkgs) · Options (NixOS + Home Manager) · Modules · Flakes (registry) · 3rd-party flakes**.
Actions per result: Try (`nix run`/`nix shell`), Install to profile, Copy NixOS snippet, Copy Home Manager snippet, Copy flake-input snippet.

Known traps:
- 2023 dependencies (Angular, Electron) are outdated; nixpkgs `electron` is much newer. Fix only the breakages that block build/run.
- Native Node addons break Nix builds. Avoid them (use pure-JS search lib).
- Electron auto-update/electron-builder do not work with the read-only store. Remove from the runtime path.
- Search endpoints change. Do NOT hard-code any endpoint before A-3 verifies it.

---

## A-0 Recon
**Do**
1. `git clone https://github.com/AppOutlet/AppOutlet ~/src/appoutlet-nix && cd ~/src/appoutlet-nix`
2. Read: `package.json` (scripts, deps, versions), `angular.json`, `main.js`, `preload.js`, `electron-builder.json`, `core/` (all), `src/app/` tree, `CONTRIBUTING.md`.
3. Identify: where the app catalog comes from; how AppImage/Flatpak/Snap install is executed; IPC channel names; `BrowserWindow` webPreferences (`contextIsolation`, `nodeIntegration`).
**Output** `notes/A-0.md` with a diagram-in-text of main↔preload↔renderer data flow and a table: provider → search fn → install fn → file:line.
**Done when** the table is complete.

## A-1 Baseline build
**Do** Create `flake.nix` devShell: `nodejs`, `yarn`, `electron` (nixpkgs). Set `ELECTRON_SKIP_BINARY_DOWNLOAD=1`. Run `yarn install --frozen-lockfile`, then the Angular build script from `package.json`, then start Electron with `ELECTRON_OVERRIDE_DIST_PATH` pointing to nixpkgs electron's dist (verify var name in Electron docs/`--help`).
**Verify** window opens (owner confirms) or, headless: `xvfb-run` smoke start without crash.
**Done when** upstream app runs unmodified; breakages and the minimal fixes are listed in `notes/A-1.md`.

## A-2 Provider interface (strangler pattern)
**Do** In `core/`, define:
```ts
interface Provider { id: string; search(q: Query): Promise<Result[]>; actions(r: Result): Action[]; }
```
Wrap existing Flatpak/AppImage/Snap code behind it **without deleting** it. Disable Snap/AppImage in UI via config flag `providers.enabled`.
**Verify** `yarn test` green; app still runs.
**Done when** all existing providers load through the interface.

## A-3 Source verification (blocking for A-4)
Verify each source with `curl -sI`/`curl -s | head`, record URL, status, format, size, rate limits, auth in `notes/A-3.md`. Mark each `OK` / `DEAD` / `NEEDS-TOKEN`. Candidates (all UNVERIFIED until checked):
| Index | Candidate source | Fallback |
|-------|-----------------|----------|
| nixpkgs packages | channel `packages.json.br` (e.g. `https://channels.nixos.org/nixos-unstable/packages.json.br`) | `nix search nixpkgs ^ --json` |
| NixOS options | channel `options.json.br` | build via `nixosOptionsDoc` → `optionsJSON` |
| Home Manager options | HM docs JSON (flake package `docs-json`, verify attr) | `nixosOptionsDoc` over HM modules |
| Registry flakes | `https://channels.nixos.org/flake-registry.json` | `nix registry list` |
| 3rd-party flakes | GitHub REST search `topic:nix-flake` (unauth limit is low; support optional token via env var, never stored in repo), FlakeHub API, flakestry, NUR repos list | local cache only |
| Modules | derived from options `declarations` + `nixosModules`/`homeManagerModules` of indexed flakes (`nix eval --json .#nixosModules --apply builtins.attrNames`) | — |
**Done when** every row has a verified source or an explicit "dropped" with reason. Ask owner if a row is dropped.

## A-4 Indexers
**Do** `core/indexer/` with one module per source, each `fetch() → normalize() → Entry[]`. Unified entry:
```ts
{ id, kind: 'package'|'option'|'module'|'flake', name, description, version?, source, url?, attr?, declaredIn?, type?, default?, example?, install: { flakeRef?, attrPath? } }
```
Rules: HTTP with timeout + retries + ETag caching; stream-parse large JSON; brotli decode (`zlib.brotliDecompressSync`) for `.br`; never block the main process (use `worker_threads`); cache in `$XDG_CACHE_HOME/appoutlet/` (resolve via `app.getPath('cache')`).
**Verify** unit tests with small fixture JSONs (`core/indexer/__fixtures__`); one real fetch run logs entry counts per kind.
**Done when** all verified sources normalize to the schema.

## A-5 Search engine
**Do** Pure-JS full-text search (MiniSearch; verify it's in nixpkgs-fetched npm deps, no native addon). Per-kind indexes in a worker. Fields: name (boost), description, attr, declaredIn. Prefix + fuzzy 0.2. Persist serialized index to cache; rebuild when source ETag changes.
**Verify** benchmark: query over full nixpkgs index < 100 ms after warm load (`notes/A-5.md` with numbers).
**Done when** benchmark recorded and passes.

## A-6 Nix provider + IPC
**Do**
- `main` process: `ipcMain.handle('nix:search' | 'nix:action' | 'nix:index-status')`.
- Run Nix via `child_process.spawn('nix', argsArray, { shell: false })` with `--extra-experimental-features 'nix-command flakes'` as separate args.
- Input validation: attr/flake refs must match `^[A-Za-z0-9._+\-/:#=?&@]+$` AND be built from index data (not free text) before use.
- Actions: Try → `nix run <ref>`; Install → `nix profile install <ref>`; Snippets are pure string generation (no exec).
- Stream stdout/stderr to renderer via `webContents.send`.
- Harden: `contextIsolation: true`, `nodeIntegration: false`, narrow preload API via `contextBridge`.
**Verify** `nix run nixpkgs#hello` via the app prints output in the log panel; invalid ref is rejected with error.
**Done when** actions work and rejected-input tests exist.

## A-7 UI (Angular)
**Do** Tabs: Packages / Options / Modules / Flakes / 3rd-party. Debounced search box (200 ms), kind-specific result cards, detail drawer (options show type/default/example/declared-in; packages show version/license/homepage if present), install-log panel, index status + manual refresh. Use `cdk-virtual-scroll` (lists exceed 100k items). Reuse existing components and theme; remove Snap/AppImage branding strings only where visible.
**Verify** `yarn build` clean; owner checks the checklist: search, switch tabs, open detail, copy snippet, run Try, refresh index.
**Done when** all checklist items pass.

## A-8 Nix packaging
**Do** `pkgs/appoutlet/default.nix`: `stdenv.mkDerivation` with `yarnConfigHook` + `yarnBuildHook` + `fetchYarnDeps` (verify hook names in pinned nixpkgs; else `mkYarnPackage`-style alternative). `ELECTRON_SKIP_BINARY_DOWNLOAD=1`. Install built app into `$out/lib/appoutlet`; wrapper:
```
makeWrapper ${electron}/bin/electron $out/bin/appoutlet \
  --add-flags $out/lib/appoutlet \
  --add-flags "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations"
```
`makeDesktopItem` + icon from `src/assets/icon/icon.png`. Do not hard-code a Nix path: use `nix` from the system PATH.
**Verify** `nix build .#appoutlet -L`, then run `result/bin/appoutlet`.
**Done when** build is green and app starts from the store path.

## A-9 NixOS module
**Do** `modules/programs/appoutlet.nix`: `programs.appoutlet.enable`, `package`. Optional `programs.appoutlet.refreshIndex = { enable; interval = "daily"; }` → systemd **user** timer + oneshot calling a headless indexer CLI (`appoutlet --reindex`; add the flag in `main.js`). Default off.
**Verify** `nix flake check`; `systemd-analyze verify` on generated units if timer enabled.

## A-10 Tests
Jest: indexer normalizers (fixtures), ref validator (reject injections: `;`, `$()`, spaces, backticks), search ranking sanity. e2e is manual (A-7 checklist).
**Done when** `yarn test` green.

## A-11 MyNixOS integration
Same pattern as README. `nixos-rebuild build` for both hosts. Do not switch.

## A-12 Docs
`docs/appoutlet.md`: usage, tabs, sources + their status from A-3, token env var for GitHub search, offline behaviour, known limits (hard fork, archived upstream).

## Risks
| Risk | Mitigation |
|------|-----------|
| Old Angular/Electron APIs removed | fix minimal; record in A-1 notes; do not upgrade Angular major unless build fails |
| Source API disappears | provider-per-source + cached index + "dropped" path in A-3 |
| Huge index memory | worker thread + virtual scroll + per-kind lazy load |
| Command injection via names | only index-derived refs, regex gate, `shell:false` |
