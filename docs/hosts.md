# Hosts

| Host | Hardware | Session | Shell | Profile | Boot entries | Build |
|------|----------|---------|-------|---------|--------------|-------|
| desktop | AMD + NVIDIA GTX 1060 | hyprland | immaterial | full | default | `nixos-rebuild build --flake .#desktop` |
| laptop | Intel + NVIDIA RTX 3050 (PRIME offload) | hyprland | immaterial | full | default | `nixos-rebuild build --flake .#laptop` |
| halos1 | Surface Pro 5 (i5-7300U, 4 GB) | hyprland (touch layer) | halo | lean | default | `scripts/halos1-deploy.sh` |

Legacy still in the tree: shells `dynisland` (module default) and `chronos` (its flake input is commented out in `flake.nix`). Removal pending owner OK.
