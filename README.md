# MyNixOS

Three hosts, one flake: `desktop`, `laptop`, `halos1`.

```
flake.nix                 inputs + the three nixosConfigurations (delegated to nix/)
nix/                      assembler, hosts, packages, devShell
hosts/<host>/             per-host config (+ hardware-configuration.nix)
modules/core/             boot, nix, user, locale, fonts, shell, home-manager
modules/hardware/         bluetooth, firmware, nvidia (switch), drives
modules/services/         networking, audio, printing, ssh, flatpak, extras
modules/programs/         default, lean, full, deskflow (+ orchard)
modules/desktop/          sessions/{mango,niri,hyprland}, shells/{chronos,halo,dynisland}, greeter, splash, droidloom
modules/theme/            palette, gtk-qt, alacritty, home
shell/halo/               Halo QML shell (rsync source)
```

See docs/ for details.
```

| host | session | shell | programs |
|---|---|---|---|
| desktop | mango | dynisland | full |
| laptop | mango | dynisland | full |
| halos1 | Hyprland (tablet) | Halo (Quickshell) | lean |

```
git add -A                                   # flakes only see tracked files
nix flake lock                               # first time: adds mango, prunes old inputs
sudo nixos-rebuild switch --flake .#desktop  # or .#laptop / .#halos1
```

mango's config is `wayland.windowManager.mango.settings` in `modules/desktop/mango.nix`
(written to `~/.config/mango/config.conf`). Monitor layout is per host:
`modules.desktop.mango.monitorRules` (see `hosts/desktop/default.nix`).
