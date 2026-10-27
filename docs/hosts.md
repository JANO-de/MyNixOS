# Hosts

| Host | Hardware | Session | Shell | Profile | Deploy |
|------|----------|---------|-------|---------|--------|
| desktop | AMD + NVIDIA (GTX 1060) | mango | dynisland | full | `nixos-rebuild build --flake .#desktop` |
| laptop | Intel + NVIDIA, CachyOS kernel | mango | dynisland | full | `nixos-rebuild build --flake .#laptop` |
| halos1 | Surface Pro 5 (i5-7300U, 4 GB) | hyprland | halo (greetd) | lean | `scripts/halos1-deploy.sh` |
