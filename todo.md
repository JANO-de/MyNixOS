# TODO

## Laptop gaming
- [ ] `git pull` on the laptop
- [ ] `lspci -k | rg -A3 -i 'vga|3d'` and send the output
- [ ] GPU module per host (AMD, Intel or hybrid NVIDIA)
- [ ] Build: `nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link`
- [ ] Test steam, `gamemoded -t`, `gamescope -- vkcube`

## Flake polish
- [ ] Decide: keep the custom module loader or move to flake-parts + import-tree
- [ ] nix-gaming input and cachix substituter
- [ ] treefmt + git-hooks, `nix flake check`
- [ ] Study fufexan (checks, hooks) and billimek (dendritic)

## Desktop
- [ ] gamescope `CAP_SYS_NICE` check after relogin
