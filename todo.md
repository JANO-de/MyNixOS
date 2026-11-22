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
- [ ] statix + deadnix in treefmt

## Desktop
- [x] gamescope CAP_SYS_NICE
