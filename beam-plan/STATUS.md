# STATUS (Beam updates after every task)

Legend: [ ] todo · [~] in progress · [x] done · [!] blocked

## M1 Orchard
- [x] O-0 Recon
- [x] O-1 Dev shell builds upstream
- [x] O-2 Package skeleton
- [x] O-3 Vendor Rust
- [x] O-4 Vendor npm provider
- [x] O-5 Offline Meson build
- [x] O-6 Wrap + desktop entry
- [x] O-7 Runtime checklist (owner)
- [x] O-8 Flake outputs + module
- [x] O-9 MyNixOS integration
- [x] O-10 Docs

## M2 AppOutlet-Nix
- [x] A-0 Recon
- [x] A-1 Baseline build
- [x] A-2 Provider interface
- [x] A-3 Source verification
- [x] A-4 Indexers
- [x] A-5 Search engine
- [x] A-6 Nix provider + IPC
- [x] A-7 UI
- [!] A-8 Nix packaging
- [!] A-9 Module (+ optional timer)
- [x] A-10 Tests
- [!] A-11 MyNixOS integration
- [x] A-12 Docs

## M3 Tokri → dynisland
- [x] T-0 Recon
- [x] T-1 Plugin contract (if absent)
- [x] T-2 Spike: shake detection
- [x] T-3 Store
- [x] T-4 Drop-in
- [~] T-5 Drag-out
- [x] T-6 Island UI
- [x] T-7 Summon + settings
- [x] T-8 Nix module
- [ ] T-9 Test matrix
- [x] T-10 Docs

## Blockers / open questions
(none)

## A-8 blocker
Native addon ABI (sqlite3) + missing upstream package-lock; needs fork commit + electron-rebuild. Ask owner.
