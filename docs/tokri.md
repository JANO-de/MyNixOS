# Tokri → dynisland plugin

Reimplementation of [ysuraj1999/tokri](https://github.com/ysuraj1999/tokri) as a dynisland plugin (QML, no binary wrapping).

## Enable

```nix
programs.dynisland.plugins.tokri.enable = true;
```

Default false. Plugin is inert while the session is locked.

## Summon

```sh
qs -c dynisland ipc call tokri toggle
```

Add a niri keybind (owner):

```kdl
Mod+Shift+B { spawn "qs" "-c" "dynisland" "ipc" "call" "tokri" "toggle"; }
```

## Settings (Settings → Plugins → Tokri)

- enabled
- shake sensitivity
- max items (default 50)
- idle auto-collapse timeout
- clear-on-logout

## Detection approach

No evdev helper (would need `input` group). Basket is summoned via keybind + drag-enter into the floating window. Drag-in uses `DropArea` accepting `text/uri-list`, `text/plain`, `image/*`. Drag-out uses `Drag.Automatic` with `text/uri-list` + `text/plain`; destination app/compositor negotiates copy vs move (Ctrl = copy, kept; plain = move, removed on finish).

## Known limits

- No shake detection (privileged input avoided). Summon via keybind or drag into window.
- Drag-out `onDragFinished` action reporting depends on compositor; some destinations may not report Move → item kept; user can remove manually.
- Plugin hidden while locked.

## Test matrix

| # | Source → action | Expect |
|---|---|---|
| 1 | File manager file → drop | kind=file, icon |
| 2 | Browser link → drop | kind=url |
| 3 | Browser image → drop | kind=image, blob saved |
| 4 | Terminal/editor text selection → drop | kind=text |
| 5 | Multiple files at once | one item per file |
| 6 | Drag out → file manager (move) | file moved, item removed |
| 7 | Drag out → file manager (ctrl copy) | file copied, item kept |
| 8 | Drag out → browser upload | file attached |
| 9 | Restart shell | items persist |
| 10 | Lock/unlock | plugin inert, no stray surface |
| 11 | Regression list (lock, launcher, lock cards) | all still work |