# ii (ii-p3drovfx) on Hyprland

Bazaar-style Quickshell config for desktop/laptop (Hyprland only). halos1 untouched.

## Options
- `modules.desktop.shell = "ii"` — select ii shell.
- `modules.desktop.ii.enable` — enable ii module (package + config link). Pending package (I-1).

## Status
- I-0 recon done. I-1 (package) blocked on ASK: matugen 4.1.0+ (nixpkgs 4.0.0), Hyprland input bump to 0.56.1+.
- I-3a layering done: hyprlandTouch.enable option, halos1 byte-identical.
- I-3b/I-4 pending owner acceptance.

## Rollback
Boot `specialisation.legacy-mango` entry (mango + dynisland) until owner accepts ii.
