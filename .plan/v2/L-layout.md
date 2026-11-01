# L feature-folder layout

Goal: pure refactor to feature-folder layout. Layout B, hand-wired, no framework. No behaviour change, no option renames, no logic edits, no flake.lock change.

Tasks: L-0 recon+map, L-1 lib/ and nix/, L-2 profiles/base, L-3 features (one per commit), L-4 dotfiles -> hosts/<h>/dotfiles, L-5 halo+dynisland sources, L-6 docs, L-7 final verify.

Rules: one task at a time, one commit per task `L-n: ...`, drv-check before/after each, nixfmt + bash -n. Owner approvals for moves listed in prompt.
