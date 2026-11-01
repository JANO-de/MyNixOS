# W immaterial-impulse on desktop + laptop

Goal: desktop and laptop run only immaterial-impulse (XephyLon/immaterial-impulse) as shell; halos1 untouched.

Tasks: W-0 recon, W-1 list before deleting, W-2 flake input + lock, W-3 delete local clone, W-4 wire HM module + hypr seed + matugen conflict, W-5 verify builds, W-6 close.

Key wiring: inputs.immaterial-impulse (nixpkgs follows ours, quickshell pinned), modules/desktop/shells/immaterial.nix enables programs.immaterial-impulse and seeds dots/.config/hypr; hosts desktop/laptop set shell=immaterial; dotfiles no longer links matugen for immaterial.
