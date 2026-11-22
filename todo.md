# TODO

## Laptop gaming
- [ ] `git pull` on the laptop
- [ ] `lspci -k | rg -A3 -i 'vga|3d'` and send the output
- [ ] GPU module per host (AMD, Intel or hybrid NVIDIA)
- [ ] Build: `nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link`
- [ ] Test steam, `gamemoded -t`, `gamescope -- vkcube`

## Flake polish
- [x] Dendritic layout: flake-parts + import-tree, parts/ (replaces the custom loader)
- [x] nix-gaming input and cachix substituter
- [x] treefmt + git-hooks, `nix flake check`
- [x] Study fufexan (ported nh, registry pinning, store optimise)
- [x] statix + deadnix in treefmt

## Desktop
- [x] gamescope CAP_SYS_NICE

## Cleanups
- [ ] Drop one of `nodejs_22` (parts/dev/fullstack.nix) or plain `nodejs` (parts/programs/lean.nix): npm collision warnings
- [ ] parts/programs/ytm-rs.nix: `xorg.libX11/libXcursor/libXi/libXrandr` -> `libx11/libxcursor/libxi/libxrandr`
- [ ] `meta.description` for the apps in parts/packages.nix (orchard, niXscout, nyaa-si, neo-mangal)
- [ ] Rewrite stale pages in .plan/docs: layout, architecture, hosts, modules, inputs (still describe modules/ and the old loader)
- [ ] Root README: remove the remaining halos1/hyprland/Halo mentions

## Open decisions (from the old .plan/todo.md)
- [ ] Compositor for desktop and laptop: niri + Noctalia vs mangowm. Then remove the unused dms/immaterial/dux/dynisland/chronos/droidloom bits
- [ ] `chronos` input (absolute path): keep, publish or vendor? Remove other unused inputs?
- [ ] niXscout: final app name (`nixscout` is a placeholder)

## Ideas
- [ ] A `checks` entry per host (build desktop and laptop in `nix flake check`)
- [ ] GitHub Actions: flake check on push, weekly `nix flake update` PR
- [ ] Secrets with sops-nix or agenix if any token is still in plain Nix
