# TODO

## Laptop gaming
- [ ] `git pull` on the laptop
- [ ] `lspci -k | rg -A3 -i 'vga|3d'` and send the output
- [ ] GPU module per host (AMD, Intel or hybrid NVIDIA)
- [ ] Build: `nh os build`
- [ ] Test steam, `gamemoded -t`, `gamescope -- vkcube`
- [ ] Decide on `hosts/laptop/xampp.nix`: nothing imports it since the dendritic move (add it to the laptop module list in `parts/hosts/laptop.nix`, or delete it)

## Flake polish
- [x] Dendritic layout: flake-parts + import-tree, parts/ (replaces the custom loader)
- [x] nix-gaming input and cachix substituter
- [x] treefmt + git-hooks, `nix flake check`
- [x] Study fufexan (ported nh, registry pinning, store optimise)
- [x] statix + deadnix in treefmt
- [x] niri + Noctalia only: mangowm and the unused shells removed
- [x] Surface leftovers removed (sunshine, moonlight, comments)
- [x] Docs and README rewritten for `parts/`
- [x] `checks` per host (`host-desktop`, `host-laptop`) and GitHub Actions (check + weekly lock update)
- [ ] `nix flake lock` after the mangowc removal, then commit `flake.lock`
- [ ] Delete the ignored leftovers by hand: `hosts/desktop/default.nix.bak`, `hosts/desktop/dotfiles/niri/config.kdl.bak`, `hosts/desktop/dotfiles/nvim/lazyvim.json.full`

## Desktop
- [x] gamescope CAP_SYS_NICE

## Open
- [ ] niXscout: final app name (`nixscout` is a placeholder)
- [ ] Secrets: all services read them from files on the host; add sops-nix or agenix only if you want them in git
