# N-1a Sources

| Tab | Source | Status | Notes |
|-----|--------|--------|-------|
| Packages | https://channels.nixos.org/nixos-26.05/packages.json.br → releases.nixos.org/.../packages.json.br | OK | HTTP 200, ~9.8 MB brotli |
| Options | .../options.json.br | OK | HTTP 200, ~1.2 MB |
| HM options | github:nix-community/home-manager/release-26.05#packages.x86_64-linux.docs-json | OK | evals to options.json store path |
| Modules | derived from options declarations | OK | no endpoint |
| Flakes | https://channels.nixos.org/flake-registry.json | OK | ~9.7 KB |
| Third-party | GitHub search API, FlakeHub, flakestry, NUR repos.json | UNVERIFIED | runtime fetchers; N-8 |

Pin channel artifacts by hash; bump via pkgs/nixscout/update.sh. Owner runs measurements on halos1.
