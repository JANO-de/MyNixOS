# M3 — Tokri → dynisland plugin

Upstream: `https://github.com/ysuraj1999/tokri` — MIT, C++/Qt (CMake). Features: shake while dragging to open a basket; drop text, URLs, images, files into it; drag items out to move; hold Ctrl while dragging out to copy. Upstream reads `/dev/input/*` to detect the mouse gesture (requires the `input` group).

Target: own Quickshell/QML shell **dynisland** at `~/Documents/MyNixOS/modules/desktop/shell/dynisland` (NixOS, niri). Decision (owner): **reimplement in QML** as a plugin module. Do not wrap the Qt binary. Tokri's source is reference for behaviour only.

Already-working features that must not regress: `Mod+Shift+L` lock, `Mod+Space` launcher, lock-screen cards, Settings → Lock screen board (drag, double-click toggle, Save persists), wrapper-fix binds.

Known traps:
- **Wayland drag-and-drop:** during a drag, other clients get no pointer events. Shake detection is the feasibility risk → T-2 spike decides the approach. No coding of the plugin before T-2.
- Quickshell `GlobalShortcut` relies on a Hyprland protocol → do not use on niri. Use `IpcHandler` + niri keybind.
- Plugin must be inert while the session is locked.
- Qt/Quickshell API names: verify each against installed version (`qs --version`, docs, source) before use.

---

## T-0 Recon (needs owner files)
**Do** Read the whole dynisland tree: entry `shell.qml`, island state machine, card/component conventions, theme singleton, settings storage (how the lock-screen board persists), IPC, how Nix wires config (`modules/desktop/shell/dynisland/*.nix`).
If any of this is not visible, **ask the owner for the files** before continuing.
**Output** `notes/T-0.md`: (a) does a plugin mechanism exist? (b) exact way to add an island state/card, (c) persistence helper, (d) how Quickshell is launched (`qs -c …`) for IPC calls, (e) theme/animation tokens to reuse.
**Done when** (a)–(e) are answered with file:line.

## T-1 Plugin contract (only if T-0(a) = no)
**Do** Smallest viable mechanism, ≤150 lines:
- `plugins/<id>/manifest.json` → `{ "id", "name", "version", "entry": "Main.qml", "settings": "Settings.qml?" }`
- `PluginHost.qml`: scans plugin dir, loads `entry` via `Loader`/`Qt.createComponent`, injects `theme`, `store` (persistence helper), `island` (expand/collapse API).
- Plugin API (documented in `plugins/README.md`): `property bool active`, `function toggle()/show()/hide()`, `signal requestExpand()`.
**Verify** Hello-world plugin appears; remove it → shell unaffected. Run regression list (above) — owner confirms.
**Done when** the hello plugin loads/unloads cleanly.

## T-2 Spike: shake-detection feasibility (BLOCKING, time-box 1–2 h)
Each experiment is a standalone QML in `spikes/`, logging to console. Start a real drag from a file manager, browser (URL/image) and terminal (text) for each.
| ID | Experiment | Question |
|----|-----------|----------|
| S1 | Fullscreen layer-shell `PanelWindow` (overlay layer, no keyboard focus) containing a `DropArea` | Do `onEntered`/`onPositionChanged` fire with coordinates during a foreign drag? Enough to detect a shake from drag motion? |
| S2 | S1 with a click-through input region | Does DnD still target the surface? (expect no — confirm) |
| S3 | Thin edge/hot-zone surfaces that expand on drag-enter | Is a fixed zone workable as a fallback to "shake"? |
| S4 | evdev/libinput helper (like upstream) reading mouse motion + button state | Works? Needs `input` group → security trade-off |
| S5 | niri IPC (`niri msg --help`, event stream) | Exposes pointer position or drag state? (likely not — verify) |
**Output** `notes/T-2.md`: results table + chosen approach, in preference order: S1 > S3 > S4. Choosing S4 requires **owner approval** (input-group exposure).
**Done when** one approach is proven working end-to-end for at least file and URL drags.

## T-3 Store
**Do** `plugins/tokri/TokriStore.qml`: model of `{ id, kind: text|url|image|file, uri, text, mime, addedAt, thumb }`. Persist JSON at `~/.local/state/dynisland/tokri/items.json` (atomic write: temp + rename; use the T-0 persistence helper or Quickshell `FileView` after verifying its API). Image/text payloads saved as files in `…/tokri/blobs/<id>.*`. Cap (default 50), dedupe by uri/hash, prune orphan blobs on load.
**Verify** add/remove/restart-shell keeps items; corrupt JSON → starts empty, does not crash.

## T-4 Drop-in
**Do** `DropArea` accepting `text/uri-list`, `text/plain`, `image/*`. Use verified `DropEvent` API for the installed Qt (`drop.urls`, `drop.text`, `drop.formats`, `drop.getDataAsString/ArrayBuffer`). Classify kind; files keep their path (no copy); images/text are written to blobs.
**Verify** test matrix (T-9) rows 1–5.

## T-5 Drag-out
**Do** Delegate with `Drag.active`, `Drag.mimeData` (`text/uri-list` + `text/plain`), `Drag.supportedActions: Qt.CopyAction | Qt.MoveAction`, `Drag.dragType: Drag.Automatic`. The destination app and compositor negotiate copy vs move (Ctrl handling lives there). On drag finish: if resulting action is Move → remove item; if Copy → keep. Verify `Drag.drop()` return/`onDragFinished` semantics in docs before coding.
**Verify** drag a file out to a file manager (move and ctrl-copy), to a browser upload field, to a chat app.

## T-6 Island UI
**Do** Collapsed: small basket pill with item count. Expanded: grid of cards (thumbnail/icon, name, hover ✕), "Clear all", click-to-copy to clipboard. Use T-0 theme tokens and easing; no new colours. Auto-expand on shake/drag-enter, auto-collapse after drop/idle (configurable timeout). Disabled and hidden while the session is locked.
**Verify** owner visual check; lock/unlock cycle leaves no stray surface.

## T-7 Summon and settings
**Do** `IpcHandler { target: "tokri"; function toggle(); function show(); function hide(); function clear() }`. Add a niri bind (document the snippet; owner adds it): `spawn "qs" "-c" "<config>" "ipc" "call" "tokri" "toggle"` — confirm the exact `qs` invocation from T-0(d). Settings page: enabled, shake sensitivity, max items, idle timeout, clear-on-logout. Persist with the existing settings mechanism.
**Verify** `qs … ipc call tokri toggle` toggles; settings survive restart.

## T-8 Nix module
**Do** Extend dynisland's module: `programs.dynisland.plugins.tokri.enable` (default false), installs the plugin directory into the config path used by the shell. If T-2 chose S4: add helper package + `users.users.<name>.extraGroups = [ "input" ]` behind a separate explicit option `…tokri.evdevHelper.enable`.
**Verify** `nix flake check`; `nixos-rebuild build --flake .#<desktop-host>`. Dynisland runs on niri (desktop); on `.#surface` (Plasma) the option must stay off and the build must still pass.
**Done when** both builds succeed.

## T-9 Test matrix (owner runs; Beam provides the sheet in `docs/tokri.md`)
| # | Source → action | Expect |
|---|-----------------|--------|
| 1 | File manager file → shake/drop | item kind=file, thumb/icon |
| 2 | Browser link → drop | kind=url |
| 3 | Browser image → drop | kind=image, blob saved |
| 4 | Terminal/editor text selection → drop | kind=text |
| 5 | Multiple files at once | one item per file |
| 6 | Drag out → file manager (move) | file moved, item removed |
| 7 | Drag out → file manager (ctrl copy) | file copied, item kept |
| 8 | Drag out → browser upload | file attached |
| 9 | Restart shell | items persist |
| 10 | Lock/unlock | plugin inert, no stray surface |
| 11 | Regression list (top of this doc) | all still work |

## T-10 Docs
`docs/tokri.md`: what it does, enable snippet, niri bind, settings, chosen detection approach (with trade-offs), known limits, test matrix.

## Risks
| Risk | Mitigation |
|------|-----------|
| No shake detection without privileged input | T-2 fallback order S1 > S3 > S4; S4 needs owner approval |
| DnD from QML differs per app/toolkit | test matrix; document unsupported sources |
| Plugin destabilises shell | T-1 isolation; regression list gate on every task |
| Data loss on crash | atomic writes; corrupt-file recovery in T-3 |
