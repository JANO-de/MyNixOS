# niXscout

Read-only browser for the Nix world. Rust + GTK4/libadwaita.

Build: `nix build .#niXscout`. Run: `NIXSCOUT_INDEX=/path/index.sqlite niXscout`.
Index: `niXscout-index <data-dir> <db-path> [flake.lock]`.

Tabs: Packages, Options, Modules, Flakes, Third-party. Search 150ms debounce, page 50.
Read-only invariant: no `std::process` in app crate.
