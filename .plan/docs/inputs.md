# Flake inputs

| Input | What | Used by | Policy |
|-------|------|---------|--------|
| nixpkgs | `nixos-26.05` | everything | base |
| home-manager | `release-26.05` | `modules`, features | follows nixpkgs |
| hyprland | compositor flake package | `modules/desktop/hyprland-session` | **no follows** (keeps Cachix valid) |
| hyprgrass | touch gestures plugin | `modules/desktop/hyprland-session/hyprland-touch.nix` | follows hyprland |
| chronos | niri fork + shell | `modules/desktop/chronos` | **impure local path** (input commented out in `flake.nix`) |
| zen-browser, opencode-flake, forge, claude-desktop, classwork | apps | `modules/programs/{lean,full}.nix`, `flake.nix` | claude-desktop and opencode: own nixpkgs; classwork: impure local path |
| arcticons | icon set | `modules/desktop/halo/default.nix` | `flake = false` |
| rust-overlay | Rust toolchain | `flake.nix`, `modules/pkgs/default.nix` (orchard needs >= 1.96) | follows nixpkgs |
| nixos-hardware | Surface modules | `hosts/halos1` | none |
| nix-cachyos-kernel | CachyOS kernel overlay | `modules/hardware/cachyos.nix` (option off) | pinned rev, do not override its nixpkgs |
| immaterial-impulse | Hyprland shell (replaces ii on desktop+laptop) | `modules/desktop/immaterial/default.nix`, `flake.nix` | follows nixpkgs; quickshell pinned upstream |

Audited 2026-10-30. Removed since: `mango` and `ii-halos` (2026-11-01, with the mango/niri sessions and the ii shell).
