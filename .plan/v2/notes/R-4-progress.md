# R-4 progress

- Step 1 (core.nix → modules/core/{boot,nix,users,locale,fonts,shell,home-manager}.nix): DONE. hosts updated to import modules/core. drv-check IDENTICAL.
- Step 2+ pending.
- Step 3 (programs.nix → modules/programs/{default,lean,full,deskflow}.nix): DONE. closure diff 0 vs original.
- Step 4 (hardware.nix → modules/hardware/{bluetooth,firmware,nvidia,drives}.nix): DONE. closure diff 0 vs original.
- Step 6 (modules/desktop/ → sessions/{hyprland,niri,mango}/, shells/{chronos,halo,dynisland}.nix, greeter/): DONE. closure diff 0.
- Step 7 (extras/xampp.nix → hosts/laptop/xampp.nix; matrix.nix → hosts/desktop/matrix.nix): DONE. closure diff 0.
- Step 8 (dynisland QML move to shell/dynisland/): PENDING ASK (owner approval). Not done.
