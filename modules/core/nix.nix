# Nix daemon settings and nixpkgs config.
{ ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.warn-dirty = false;
  nixpkgs.config.allowUnfree = true;
}
