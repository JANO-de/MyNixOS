
# dynisland UI work (hard rules)
- You cannot run or see the shell (no Wayland session, runs as root). Never run `dynisland`, `qs`, or offscreen. Never claim a UI change works. Verify only with `qmllint` and by reading the code.
- Make ONE complete change per request, then stop and say "test: dynisland restart". The user reports what happened. Do not iterate by guessing.
- Show/hide rule: hidden = `visible: false` or `enabled: false` plus the animation, never only `opacity: 0`.
- Click regions: when sliding or resizing a PanelWindow, the `mask: Region` and window height must be bound to the same animated value as the visual. Keep a minimum hot zone (>= 4px) at the screen edge so hover can bring it back.
- Hover to reveal: use one HoverHandler on the always-present edge strip, not on the hidden item.
- Before editing, list the files and the exact bindings you will change (3 lines max).
