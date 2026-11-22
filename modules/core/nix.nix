# Nix daemon settings, nh (rebuilds + weekly cleanup), registry pinning and nixpkgs config.
{
  config,
  inputs,
  lib,
  ...
}:

let
  flakeInputs = lib.filterAttrs (_: v: lib.isType "flake" v) inputs;
in
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
      auto-optimise-store = true;
      # keep build deps alive for direnv / dev shells
      keep-outputs = true;
      keep-derivations = true;
    };
    # pin the registry and NIX_PATH to this flake's inputs: no re-downloading nixpkgs on `nix run`
    registry = lib.mapAttrs (_: v: { flake = v; }) flakeInputs;
    nixPath = lib.mapAttrsToList (name: _: "${name}=flake:${name}") config.nix.registry;
  };

  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 30d --keep 5";
    };
    flake = "/home/jano/Proyectos/MyNixOS";
  };

  nixpkgs.config.allowUnfree = true;
}
