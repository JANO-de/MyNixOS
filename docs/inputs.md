# Flake inputs

| Input | What | Used by | Policy |
|-------|------|---------|--------|
| nixpkgs | `nixos-26.05` | everything | base |
| home-manager | `release-26.05` | `modules/core`, desktop modules | follows nixpkgs |
| mango | MangoWM modules | `nix/hosts.nix`, `sessions/mango` (legacy) | own nixpkgs (needs its wlroots/scenefx) |
| hyprland | compositor flake package | `sessions/hyprland`, `shells/ii.nix` | **no follows** (keeps Cachix valid) |
| hyprgrass | touch gestures plugin | `hyprland-touch.nix` | follows hyprland |
| chronos | niri fork + shell | `chronos.nix`, `niri.nix`, `dynisland.nix` | **impure local path** |
| zen-browser, opencode-flake, forge, claude-desktop, classwork | apps | `modules/programs/{full,lean}.nix`, `nix/hosts.nix` | claude-desktop and opencode: own nixpkgs; classwork: impure local path |
| arcticons | icon set | `shells/halo.nix` | `flake = false` |
| rust-overlay | Rust toolchain | `nix/hosts.nix`, `nix/packages.nix` (orchard needs >= 1.96) | follows nixpkgs |
| nixos-hardware | Surface modules | `hosts/halos1` | none |
| nix-cachyos-kernel | CachyOS kernel overlay | `nix/hosts.nix` (flag off) | pinned rev, do not override its nixpkgs |

All inputs are referenced somewhere (audited 2026-10-30). ii forks are **not** inputs: they are pinned in `pkgs/ii-*/default.nix` by `rev` + `hash`.
