# AppOutlet-Nix (minimal viable store)

Re-scope (owner decision): minimal viable store. Full 5-tab index (options/modules/flakes/3rd-party) deferred; this release ships **Packages (nixpkgs) + Options (NixOS) search only**, with copy/install actions.

## Enable

```nix
programs.appoutlet.enable = true;
```

## Status

- A-0 recon, A-1 baseline build, A-2 provider interface, A-3 source verification, A-4/A-5 indexers/search engine, A-6 IPC, A-7 UI: implemented in the original fork (lost; needs re-derivation for the full 5-tab product).
- A-8 packaging, A-9 module, A-11 MyNixOS integration: **deferred** — blocked on native addon (sqlite3) rebuild and fork re-derivation.
- Minimal viable scope (this doc): nixpkgs packages + NixOS options search, `nix run`/`nix profile install` actions, copy NixOS snippet. No Electron native addon (pure-JS search). No modules/flakes/3rd-party tabs.

## Known limits

- Hard fork of archived upstream (MIT). No upstream sync.
- Electron 43 / Node 24 vs upstream Electron 19 / Node 16: large version gap; fix breakages only.
- Source APIs per `notes/A-3.md` (verified). GitHub search needs optional token via env var (never stored).

## Update procedure

1. Bump sources in `pkgs/appoutlet-nix/default.nix`.
2. Reset hashes to `lib.fakeHash`, rebuild, copy real hashes.
3. `nix flake check` + `nixos-rebuild build --flake .#desktop`.