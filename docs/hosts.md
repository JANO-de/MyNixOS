# Hosts

| Host | Hardware | Session | Shell | Profile | Boot entries | Build |
|------|----------|---------|-------|---------|--------------|-------|
| desktop | AMD + NVIDIA GTX 1060 | hyprland | immaterial | full | default | `nixos-rebuild build --flake .#desktop` |
| laptop | Intel + NVIDIA RTX 3050 (PRIME offload) | hyprland | immaterial | full | default | `nixos-rebuild build --flake .#laptop` |
| halos1 | Surface Pro 5 (i5-7300U, 4 GB) | hyprland (touch layer) | ii (temporary test) / halo | lean | default | `scripts/halos1-deploy.sh` |

Legacy still in the tree: session `mango`, shell `dynisland`, shell `chronos`/niri (module defaults). Removal pending owner OK.
