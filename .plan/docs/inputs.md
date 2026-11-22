# Flake inputs

| Input | What | Used by | Policy |
|-------|------|---------|--------|
| nixpkgs | `nixos-26.05` | everything | base |
| home-manager | `release-26.05` | `parts/lib.nix`, `parts/desktop/dotfiles.nix` | follows nixpkgs |
| stylix | theming | `parts/lib.nix`, `parts/theme/stylix.nix` | `release-26.05`, follows nixpkgs |
| niri-flake | niri compositor | `parts/desktop/compositor.nix`, `parts/lib.nix` | pinned rev, follows nixpkgs |
| noctalia | desktop shell | `parts/desktop/shell.nix`, `parts/lib.nix` | own nixpkgs |
| nix-gaming | Steam platform optimizations | `parts/lib.nix`, `parts/gaming.nix` | follows nixpkgs |
| nix-cachyos-kernel | CachyOS kernel overlay | `parts/hardware/cachyos.nix` (option off) | pinned rev, do not override its nixpkgs |
| rust-overlay | Rust toolchain | `parts/lib.nix`, `parts/packages.nix` (orchard needs >= 1.96) | follows nixpkgs |
| forge | OpenCode terminal UI | `parts/lib.nix`, `parts/programs/lean.nix` | follows nixpkgs |
| zen-browser, opencode-flake, viu, tuimessenger, spicetify-nix, ytm-player | apps | `parts/programs/` | upstream defaults |
| claude-desktop | Claude Desktop wrapper | `parts/programs/apps.nix` | own nixpkgs: it still uses the removed `nodePackages` attr |
| nyaa-si-src, neo-mangal-src | plain sources (`flake = false`) | `pkgs/overlay.nix`, `parts/packages.nix` | packaged in `pkgs/` |
| flake-parts, import-tree | flake structure | `flake.nix` | n/a |
| treefmt-nix, git-hooks | formatter, lint, pre-commit | `parts/dev.nix` | follow nixpkgs |

Removed: mangowc (compositor), the old shells and the `chronos` / `classwork` local-path inputs.
