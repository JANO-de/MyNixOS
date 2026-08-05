{ config, lib, inputs, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  # Make nixpkgs-unstable available to any module as `pkgs-unstable`
  _module.args.pkgs-unstable =
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
}
