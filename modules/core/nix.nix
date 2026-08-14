{ config, lib, inputs, pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  # Noctalia's binary cache (also declared in flake.nix nixConfig so the first
  # build works before this configuration is applied).
  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };

  # Make nixpkgs-unstable available to any module as `pkgs-unstable`
  _module.args.pkgs-unstable =
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
}
