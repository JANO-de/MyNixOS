# N: niXscout (read-only Nix browser, Rust + GTK4/libadwaita)

Real names: `pkgs/niXscout/`, `programs.niXscout.enable`, binaries `niXscout`, `niXscout-index`, doc `docs/niXscout.md`.
Product: five tabs (Packages, Options, Modules, Flakes, Third-party) in an `AdwViewSwitcher`; Bazaar-style cards, details in an `AdwNavigationView`.

## Invariants
- **Read-only.** No install, no `nix` execution, no `std::process` / `Command::new` in `crates/app`. Allowed: copy snippets to the clipboard, open a homepage with `gtk::UriLauncher`.
- Memory is the point (halos1, 4 GB). Never load the index into RAM (SQLite `cache_size` ~2 MB, `query_only=1`, lazy open); lists hold ids/titles only, page 50; search debounce 150 ms with generation numbers; workers = `std::thread` + `async_channel`; no timers, no daemon, no network at startup.
- Crate budget: `gtk4`, `libadwaita`, `rusqlite` (system sqlite), `serde`, `serde_json`, `ureq` (rustls), `pulldown-cmark`, `async-channel`, `brotli` (index only). No tokio/reqwest/webkit. No `unsafe`. Another crate = report cost first.
- Nixpkgs 26.05: rustc 1.95.0, gtk4 4.22.5, libadwaita 1.9.4, sqlite 3.51.2 (features `v4_22`, `v1_9`).

## Data sources (verified 2026-10-28 except Third-party)
| Tab | Source | Status |
|-----|--------|--------|
| Packages | `https://channels.nixos.org/nixos-26.05/packages.json.br` (~9.8 MB) | OK |
| Options | `.../options.json.br` (~1.2 MB) | OK |
| HM options | `github:nix-community/home-manager/release-26.05#packages.x86_64-linux.docs-json` | OK |
| Modules | derived from option `declarations` | OK |
| Flakes | `https://channels.nixos.org/flake-registry.json` | OK |
| Third-party | GitHub topic `nix-flake`, FlakeHub, flakestry, NUR `repos.json` | UNVERIFIED (runtime) |

## State (snapshot)
- `crates/index` (208 lines) + `schema.sql`, `crates/app/src/main.rs` (124 lines, view switcher), `crates/net/src/lib.rs` (31 lines, stub).
- `pkgs/niXscout/data/*.json` are **placeholders** (3-16 bytes), not pinned `fetchurl` derivations: the package builds, but the index is empty.
- Missing: `update.sh`, desktop entry, icons, `scripts/nixscout-measure.sh`.

## Open tasks
- **N-1b** Data: replace the placeholders with `fetchurl` (hash-pinned) derivations in `index.nix` for packages, options, HM options, registry; `pkgs/niXscout/update.sh` bumps them. Verify row counts against `jq`.
- **N-8** `crates/net`: one module per third-party source, ETag + 24 h TTL cache DB, 10 s timeouts, `User-Agent: niXscout/<ver>`, optional `GITHUB_TOKEN` from the environment, stop on 403/429. Tests use recorded fixtures (no network).
- **N-9/N-10** UI: card grid (`GridView` + `SignalListItemFactory`), search (Ctrl+F), empty/offline/error states, detail pages per kind, Markdown to Pango in `crates/app/src/md.rs` (unit tests on 10 real option descriptions).
- **N-11** Measure idle PSS (`/proc/<pid>/smaps_rollup`) vs a hello-world baseline; targets: <= baseline + 30 MB with Packages loaded, search p95 <= 100 ms desktop / 250 ms halos1, cold window < 300 ms halos1. Owner measures on halos1.
- **N-12** Packaging polish: wrapper sets `NIXSCOUT_INDEX`, desktop entry, symbolic icon; enabled on all three hosts today.
- **N-13** Update `docs/niXscout.md`; owner checklist: launch < 1 s desktop; five tabs; search "firefox"; `services.openssh.enable` page shows type/default; copy buttons; Third-party online + cached offline; closing the window ends the process.

## Verify (every task)
```
nix develop -c cargo clippy -- -D warnings && nix develop -c cargo test
nix build .#niXscout && ls result/share/niXscout* 
grep -rn 'Command::new\|std::process' pkgs/niXscout/crates/app    # must be empty
```
