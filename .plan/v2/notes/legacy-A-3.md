# A-3 Source verification

| Index | Source | Status | URL / attr | Format | Notes |
|-------|--------|--------|------------|--------|-------|
| nixpkgs packages | channels.nixos.org → releases.nixos.org | OK | https://channels.nixos.org/nixos-unstable/packages.json.br → releases.../packages.json.br | brotli JSON (~10.4 MB) | 302 redirect, 200 final |
| NixOS options | channels.nixos.org → releases.nixos.org | OK | https://channels.nixos.org/nixos-unstable/options.json.br → releases.../options.json.br | brotli JSON (~1.3 MB) | 302 redirect, 200 final |
| Home Manager options | flake package docs-json | OK | `github:nix-community/home-manager/release-26.05#packages.x86_64-linux.docs-json` | derivation options.json.drv | verified attr exists |
| Registry flakes | channels.nixos.org | OK | https://channels.nixos.org/flake-registry.json | JSON (ETag) | 200, cache-control 300 |
| 3rd-party flakes (GitHub topic) | GitHub REST search | OK | `https://api.github.com/search/repositories?q=topic:nix-flake` | JSON (total_count present) | unauth rate limit low; support optional token via env var, never stored |
| 3rd-party flakes (FlakeHub) | FlakeHub | OK | https://flakehub.com | HTML | reachable |
| 3rd-party flakes (flakestry) | flakestry.dev | OK | https://flakestry.dev | HTML | reachable |
| 3rd-party flakes (NUR) | raw.githubusercontent.com | OK | https://raw.githubusercontent.com/nix-community/NUR/master/repos.json | JSON | reachable |
| Modules | derived from options `declarations` + indexed flakes' nixosModules/homeManagerModules | OK (design) | `nix eval --json .#nixosModules --apply builtins.attrNames` | JSON | no direct endpoint; derive locally |
