# M1 — Orchard → NixOS

Upstream: `https://github.com/SFG5453/Orchard` (YouTube Music client). Qt 6 QML UI, Rust audio core, Meson build, Node-based YouTube provider, git submodules. AGPL-3.0-or-later + PolyForm Shield (adaptive-mix engine files). Upstream ships a `flake.nix` and `.envrc` — start from them.

Known build requirements (from upstream README, verify in `docs/DEVELOPMENT.md`):
Meson ≥1.12, CMake ≥3.24, Ninja, Qt ≥6.8 (Quick, QML, Network, Multimedia, + WebView/WebEngine on Linux), C++20, Node/npm, Rust ≥1.96. Adaptive mix needs a WebGPU-capable GPU + FFmpeg.

Known traps:
- README build steps clone `orchard-v4`, not `Orchard`. Determine which repo is canonical (`git remote -v`, `.gitmodules`, release tags) before pinning.
- Upstream ships a bootstrapper/updater. The Nix store is read-only: the self-updater must be disabled or unused.
- Meson probably invokes cargo/npm during compile → fails in the Nix sandbox unless deps are vendored.
- Rust 1.96 may be newer than nixpkgs' `rustc`. Check before choosing a toolchain.
- PolyForm Shield is not a free licence for nixpkgs purposes. Package lives in MyNixOS only (personal use). Needs `allowUnfree` or a custom licence attr.

---

## O-0 Recon
**Do**
1. `git clone --recurse-submodules https://github.com/SFG5453/Orchard ~/src/orchard && cd ~/src/orchard`
2. Read: `flake.nix`, `flake.lock`, `.envrc`, `meson.build`, `meson.options`, `Cargo.toml`, `.gitmodules`, `docs/DEVELOPMENT.md`, `AGENTS.md`, `providers/youtube/package.json`, `bootstrapper/`, `docs/app/connect.md`.
3. `grep -rn "cargo\|npm" meson.build meson/ app/ core/ --include=meson.build --include=*.py --include=*.sh` to find where Meson calls cargo/npm.
4. `rustc --version` inside `nix develop` vs required version.

**Output** `notes/O-0.md`: upstream flake outputs (`nix flake show`), submodule list with URLs, exact cargo/npm invocation points, runtime deps (ffmpeg, audio backend, Vulkan), ports used by Orchard Connect, canonical repo decision.
**Done when** all five items are written with evidence (command output or file:line).

## O-1 Upstream builds in dev shell
**Do** `nix develop` (if upstream flake has a devShell; otherwise create `devShell.nix` from O-0 deps), then run exactly:
```
npm ci --prefix providers/youtube
meson setup build/dev --buildtype debug
meson compile -C build/dev
meson test -C build/dev --print-errorlogs
```
**Verify** `./build/dev/orchard --version` or equivalent starts without crash (headless check: `QT_QPA_PLATFORM=offscreen`).
**Done when** the build completes; any missing dep is added to the shell and listed in `notes/O-1.md`.

## O-2 Package skeleton
**Do** Create `pkgs/orchard/default.nix` (`stdenv.mkDerivation`):
- `src = fetchFromGitHub { owner; repo; rev = "<pinned commit>"; fetchSubmodules = true; hash = lib.fakeHash; }`
- `nativeBuildInputs`: meson, ninja, cmake, pkg-config, nodejs, rustc, cargo, `qt6.wrapQtAppsHook`
- `buildInputs`: `qt6.qtbase qtdeclarative qtmultimedia qtwebview qtwebengine`, ffmpeg, plus audio/GPU libs found in O-0 (pipewire/alsa/vulkan-loader/openssl as needed)
- Pin by commit, not branch.
**Verify** `nix build .#orchard -L 2>&1 | tail -40` → first failure should be hash/vendoring, not missing Qt.
**Done when** source hash resolved and build reaches the compile phase.

## O-3 Vendor Rust
**Do** Add `cargoDeps = rustPlatform.importCargoLock { lockFile = "${src}/Cargo.lock"; outputHashes = { … }; }` (or `fetchCargoVendor` — verify which exists in the pinned nixpkgs) and `rustPlatform.cargoSetupHook`. Fill `outputHashes` for each git dependency the error names.
Toolchain: if nixpkgs `rustc` < required, add a pinned `rust-overlay`/`fenix` flake input and use its toolchain via `makeRustPlatform`.
**Verify** `nix build .#orchard -L` fails later than before and no "failed to download" lines appear.
**Done when** cargo compiles all crates offline.

## O-4 Vendor Node provider
**Do** Prefer a separate derivation: build `providers/youtube` with `buildNpmPackage` (`npmDepsHash = lib.fakeHash` first), then give Meson the built output (patch the Meson step in `postPatch`, do not edit upstream sources in the repo).
Alternative if Meson requires in-tree `node_modules`: `fetchNpmDeps` + `npmConfigHook` with `npmRoot = "providers/youtube"`.
**Verify** provider artefact exists in `$out` (`nix build .#orchard && find result -path '*youtube*' | head`).
**Done when** no network access occurs during the npm step.

## O-5 Offline Meson build
**Do** Ensure Meson's cargo calls use `--offline`/`--frozen` (via `CARGO_NET_OFFLINE=true` or patch). Set `mesonBuildType = "release"`; pass options from `meson.options` that disable updater/bootstrapper if one exists.
**Verify** `nix build .#orchard -L` succeeds. `result/bin/` contains the app binary.
**Done when** build is fully green in the sandbox.

## O-6 Wrap and desktop integration
**Do**
- Qt wrapper handles QML/plugin paths; add `runtimeDeps` to wrapper: `ffmpeg` on PATH; `LD_LIBRARY_PATH` prefix for `vulkan-loader`, `libglvnd`, `pipewire` if dlopen'd (find via `ldd` + `strings`; justify each).
- Install `.desktop` (`makeDesktopItem`, `Categories = AudioVideo;Audio;Player;`, `MimeType` only if upstream declares it) and icon from `app/qml/assets/orchard-logo.png` into hicolor.
- Disable/skip self-update paths.
**Verify** `ldd result/bin/orchard | grep "not found"` → empty. `QT_QPA_PLATFORM=offscreen result/bin/orchard --help` exits cleanly.
**Done when** no unresolved libs; desktop file validates (`desktop-file-validate`).

## O-7 Runtime checklist (owner performs; Beam writes the list into `docs/orchard.md`)
- Window renders under Wayland (Surface/Plasma and niri desktop).
- Google sign-in works through WebEngine.
- Output device list shows host audio devices; playback works.
- Media keys / MPRIS visible in `playerctl status`.
- Tray icon appears.
- Adaptive mix: expected to need WebGPU. Record result per host; failure on the Surface GPU is a documented limit, not a blocker.

## O-8 Flake outputs and module
**Do** Expose: `packages.x86_64-linux.orchard`, `apps.x86_64-linux.orchard`, `overlays.default`, `nixosModules.orchard`.
Module `modules/programs/orchard.nix`:
```
options.programs.orchard = { enable = mkEnableOption "Orchard"; package = mkPackageOption …; };
config = mkIf cfg.enable { environment.systemPackages = [ cfg.package ]; };
```
Add `openFirewall` only after verifying Orchard Connect ports in `docs/app/connect.md` (else `UNVERIFIED`, skip).
Licence: `meta.license` lists AGPL-3.0-or-later and a custom PolyForm Shield entry (`{ fullName = "PolyForm Shield 1.0.0"; free = false; }`). Check `allowUnfree` on hosts.
**Verify** `nix flake check`; `nix eval .#nixosConfigurations.surface.config.programs.orchard.enable`.
**Done when** both pass.

## O-9 MyNixOS integration
**Do** Add flake input or vendor `pkgs/orchard` into MyNixOS, import module, set `programs.orchard.enable = true;` on chosen hosts.
**Verify**
```
nixos-rebuild build --flake ~/Documents/MyNixOS#surface
nixos-rebuild build --flake ~/Documents/MyNixOS#<desktop-host>
```
**Done when** both build. Report closure size (`nix path-info -Sh ./result`). Do not switch.

## O-10 Docs
`docs/orchard.md`: enable snippet, options, known limits (WebGPU, updater disabled, licence note), update procedure (bump `rev`, reset hashes to `lib.fakeHash`, rebuild).

## Risks
| Risk | Mitigation |
|------|-----------|
| Rust version > nixpkgs | O-3 pinned toolchain input |
| Meson shells out to network | O-4/O-5 vendoring + patch in `postPatch` |
| WebEngine sign-in breaks sandboxed | test with default env first; only then add flags (document each) |
| Submodule URL moves | pin commit; `fetchSubmodules` hash change is visible in O-2 |
