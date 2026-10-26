# MyNixOS

Three hosts, one flake: `desktop`, `laptop`, `halos1`.

```
flake.nix                 inputs + the three nixosConfigurations
hosts/<host>/             per-host config (+ hardware-configuration.nix)
modules/core.nix          boot, nix, user, locale, fonts, zsh, Home Manager wiring
modules/hardware.nix      bluetooth, firmware, NVIDIA (switch), Elements drive (switch)
modules/services.nix      networking, audio, printing, ssh, flatpak, qmk + switchable
                          extras: sunshine, waydroid, powertop, smartd
modules/programs.nix      "full" profile (desktop, laptop) or "lean" (halos1)
modules/desktop/          session (mango | niri), shell (dynisland | chronos), SDDM
modules/extras/           host-specific big services: xampp (laptop), matrix (desktop)
modules/home.nix          Home Manager: GTK/Qt theme + alacritty
modules/theme.nix         one palette for everything (catppuccin mocha / mauve)
```

| host | session | shell | programs |
|---|---|---|---|
| desktop | mango | dynisland | full |
| laptop | mango | dynisland | full |
| halos1 | mango (tablet experiment) | dynisland | lean |

```
git add -A                                   # flakes only see tracked files
nix flake lock                               # first time: adds mango, prunes old inputs
sudo nixos-rebuild switch --flake .#desktop  # or .#laptop / .#halos1
```

mango's config is `wayland.windowManager.mango.settings` in `modules/desktop/mango.nix`
(written to `~/.config/mango/config.conf`). Monitor layout is per host:
`modules.desktop.mango.monitorRules` (see `hosts/desktop/default.nix`).
