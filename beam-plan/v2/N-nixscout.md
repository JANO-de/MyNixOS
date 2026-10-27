# M1: nixscout (working name; the owner may rename it)

A read-only, Bazaar-style browser for the Nix world. Name lives in one place (`APP_ID`, binary, package, module): renaming = one grep.

## Product

Five tabs (`AdwViewSwitcher`): **Packages · Options · Modules · Flakes · Third-party**.
Look and feel = Bazaar (GTK4/libadwaita store): search bar on top, grid of rounded cards (icon, title, one-line summary), click → details page in an `AdwNavigationView`, empty/offline states with `AdwStatusPage`. Study the real thing in N-1; do not copy code, copy structure.
Read-only: **no install, no `nix` execution, no `std::process` in the app crate.** Allowed: copy snippets to the clipboard (`nix shell nixpkgs#x`, `environment.systemPackages = [ pkgs.x ];`, `inputs.x.url = "...";`, option assignment) and open a homepage URL through `gtk::UriLauncher`.

| Tab | Content | Source (candidates carried over from `notes/legacy-A-3.md`: **re-verify each**) | When fetched |
|-----|---------|------|------|
| Packages | nixpkgs attrs: name, version, description, homepage, license, platforms, maintainers, unfree/broken | `https://channels.nixos.org/nixos-26.05/packages.json.br` → fixed-output `fetchurl` | build time |
| Options | NixOS options + Home Manager options: type, default, example, declared-in, description | `.../options.json.br`; HM: `github:nix-community/home-manager/release-26.05#packages.x86_64-linux.docs-json` | build time |
| Modules | one card per module: `programs.x`/`services.x` with its `enable` option, option count, file | derived locally from options `declarations` (no endpoint exists) | build time |
| Flakes | NixOS flake registry + the inputs of this repo's `flake.lock` | `https://channels.nixos.org/flake-registry.json` | build time (+ manual refresh) |
| Third-party | GitHub topic `nix-flake`, FlakeHub, flakestry, NUR repos | GitHub search API, FlakeHub, flakestry, `NUR/master/repos.json` | **runtime**, only when the tab is opened or Refresh is pressed |

The channel artifacts are pinned by hash and bumped by a script (`pkgs/nixscout/update.sh`), so the 4 GB Surface never evaluates nixpkgs. If N-1 finds a source dead or changed, **ASK** before substituting.

## Architecture (Rust workspace in `pkgs/nixscout/`)

```
Cargo.toml  Cargo.lock                workspace; release: lto, codegen-units=1, panic=abort, strip (N-11 measures opt-level s vs 3)
crates/index/   lib + bin nixscout-index   JSON → index.sqlite (rusqlite, FTS5)
crates/app/     bin nixscout               GTK4/libadwaita UI
crates/net/     lib                        third-party fetchers + cache (ureq, blocking)
data/           fetchurl derivations (packages, options, hm-options, registry)
default.nix  index.nix  update.sh  nixscout.desktop  icons/
```

Dependency budget (adding any other crate → report why and RSS/size cost first): `gtk4`, `libadwaita`, `rusqlite` (system SQLite, not bundled), `serde`, `serde_json`, `ureq` (rustls), `pulldown-cmark` (descriptions → Pango markup), `async-channel`, `brotli` (index crate only, build time). **No** tokio, reqwest, webkit, image decoding. No `unsafe`.

Memory rules (the whole point of this app):
- Never load the index into RAM. SQLite `cache_size` ≈ 2 MB, small `mmap_size`, `PRAGMA query_only=1`, open lazily.
- Lists hold only ids/titles (`gio::ListStore` of tiny objects), page 50 rows at a time, details fetched on open and dropped on back.
- Search: 150 ms debounce; each query tagged with a generation number, stale results discarded.
- Workers = `std::thread` + `async_channel` → `glib::spawn_future_local`. No timers, no polling, no tray, no daemon: process exits when the window closes.
- No network at startup. Offline start works; Third-party shows its cache + a banner.
- Icons: Adwaita symbolic icons only.

Budgets are **measured, never guessed**: N-2 builds a hello-world libadwaita window and records its idle PSS (`/proc/<pid>/smaps_rollup`). Targets: idle PSS ≤ baseline + 30 MB with the Packages tab loaded; search p95 ≤ 100 ms on desktop and ≤ 250 ms on halos1 (≈120k rows); cold window < 300 ms on halos1. Owner runs the measurement on halos1.

## Tasks

### N-0 Recon
**Do** Read `pkgs/orchard/default.nix` (the Rust packaging pattern here) and `docs/orchard.md`, `modules/home.nix` (GTK/Qt theming), `modules/programs/orchard.nix`. Record: `nix eval --raw nixpkgs#rustc.version`, `nixpkgs#libadwaita.version`, `nixpkgs#gtk4.version`, `nixpkgs#sqlite.version`; whether `rust-overlay` is needed (MSRV of chosen crates vs nixpkgs rustc).
**Done when** `notes/N-0.md` answers: packaging pattern to reuse, versions, `gtk4`/`libadwaita` crate versions and `v4_x`/`v1_x` features that match the system versions (check with `pkg-config --modversion`).

### N-1 Source verification + Bazaar study
**Do** (a) For every row of the table: URL, the exact command used (`curl -sIL`, `nix eval`, …), HTTP status, size, 3 sample records, field names, rate limit and terms of use. Re-confirm `legacy-A-3.md`; mark each `OK` or `UNVERIFIED`. (b) Read Bazaar's source (find the repo with `curl -sIL`/search; **UNVERIFIED** until confirmed) and its UI files; map each widget/page to a libadwaita widget in a table.
**Output** `notes/N-1a-sources.md`, `notes/N-1b-bazaar-ui.md`.
**Done when** every tab has a verified data source or an **ASK**.

### N-2 Dev shell + baseline
**Do** `devShells.default` (rustc, cargo, `pkg-config`, gtk4, libadwaita, sqlite, `nixfmt`) in `nix/dev.nix` (or `flake.nix` if R-3 is not done: tiny, movable). Hello-world `AdwApplicationWindow`. Write `scripts/nixscout-measure.sh <pid>`: prints PSS, RSS, threads, open fds, startup time.
**Verify** `nix develop -c cargo run`; record idle PSS in `notes/N-2.md`; set the numeric budgets from the baseline.
**Done when** budgets are numbers in `notes/N-2.md`.

### N-3 Schema
**Do** Write `docs/nixscout/schema.md` and `crates/index/src/schema.sql`: `items(id, kind, key, title, summary, version, flags)`, FTS5 table over `key, title, summary` (prefix indexes), `details(id, json)`, `meta(schema_version, source_rev, built_at)`. Kinds: `package option module flake tpflake`. Third-party cache is a separate DB in `$XDG_CACHE_HOME/nixscout/` with the same shape.
**Verify** a 20-row fixture loads and `MATCH` queries return expected rows (`cargo test`).

### N-4 Indexer: packages
**Do** Parse `packages.json` (brotli) streaming (`serde_json` from a reader, not a full `Value`). **Verify** row count = number of attrs in the JSON (`jq '.packages|length'`); 10 random attrs match field by field; indexer peak RSS recorded (`/usr/bin/time -v`).

### N-5 Indexer: options
**Do** NixOS + HM options; keep `declarations`; descriptions stay Markdown. **Verify** counts equal `jq 'length'` of each JSON; 10 random options match.

### N-6 Indexer: modules
**Do** Group options by declaring file / first two path segments; module card = title (`programs.git`), enable option if any, option count, file. **Verify** 10 known modules appear (`programs.git`, `services.openssh`, `hardware.bluetooth`, …) with correct counts.

### N-7 Indexer: flakes
**Do** Registry JSON + this repo's `flake.lock` root inputs (owner, repo, rev, lastModified). **Verify** count equals registry entries; every lock input present.

### N-8 Third-party fetchers (runtime)
**Do** `crates/net`: one module per source, each returns the common record type. ETag/`If-None-Match`, 24 h TTL, cache DB, timeouts 10 s, `User-Agent: nixscout/<version>`, optional `GITHUB_TOKEN` from the environment, polite rate-limit handling (stop on 403/429, show a banner). Tests use recorded fixtures: **no network in tests**.
**Verify** `cargo test`; one manual run per source, recorded in `notes/N-8.md`.

### N-9 UI shell
**Do** Window (default 900×680, adaptive), 5-page view switcher, `GtkSearchEntry` (Ctrl+F focuses), card grid (`GridView` + `SignalListItemFactory`), empty/offline/error states, infinite paging, keyboard navigation. Query layer behind a trait so the UI never touches SQL.
**Verify** `cargo clippy -- -D warnings`, `cargo test`; UI smoke headless only if `weston --backend=headless-backend.so` or `xvfb-run` exists (check, else skip). Beam cannot see visuals: write the owner checklist (N-13).

### N-10 Detail pages
**Do** Per kind: header, facts table, description, copy buttons, "open homepage". Markdown → Pango markup in `crates/app/src/md.rs` (headings, code, lists, emphasis, links; strip unknown nodes). Options show type/default/example/declared-in. Modules show the enable snippet. Third-party shows stars, last update, description, link.
**Verify** unit tests for `md.rs` on 10 real option descriptions taken from `options.json`.

### N-11 Performance pass
**Do** Measure on desktop (Beam) and halos1 (owner runs `scripts/nixscout-measure.sh`). Compare against N-2 budgets; fix only the worst offender; re-measure; try `opt-level="s"` vs `3` and record. **Done when** all budgets met or the owner accepts the numbers.

### N-12 Packaging + integration (after R-3)
**Do** `pkgs/nixscout/default.nix` (`rustPlatform.buildRustPackage`, `cargoLock.lockFile`, `meta.mainProgram`, `meta.license`), `index.nix` (runs `nixscout-index` over `data/*` → `$out/share/nixscout/index.sqlite`), wrapper sets `NIXSCOUT_INDEX`, desktop entry + symbolic icon. Flake: `packages`, `apps`, overlay, `nixosModules.nixscout` = `programs.nixscout.enable` (+ `package`). Enable on `desktop`, `laptop`, `halos1` host files.
**Verify**
```
nix build .#nixscout && ls result/share/nixscout/index.sqlite
nix flake check
grep -rn 'Command::new\|std::process' pkgs/nixscout/crates/app   # must be empty (read-only invariant)
for h in desktop laptop halos1; do nixos-rebuild build --flake .#$h; done
```
**Done when** all green. The owner deploys.

### N-13 Docs + owner checklist
**Do** `docs/nixscout.md`: usage, options, data sources, update procedure (`update.sh`), known limits, budgets achieved. Owner checklist (yes/no): launches under 1 s on desktop; five tabs switch; search "firefox" returns packages; option `services.openssh.enable` page opens with type/default; copy buttons put text on the clipboard; Third-party works online, shows cache offline; window close ends the process (`pgrep nixscout` empty); halos1 idle PSS number reported.
**Done when** `STATUS.md` updated and the report lists what is untested.
