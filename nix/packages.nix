{ inputs, system }:
let
  inherit (inputs) nixpkgs self;
  pkgs = import nixpkgs { inherit system; };
  orchardPkg =
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ inputs.rust-overlay.overlays.default ];
        config.allowUnfree = true;
      };
    in
    pkgs.callPackage ../pkgs/orchard/default.nix { };
  nixscoutPkg = pkgs.callPackage ../pkgs/nixscout/default.nix { };
in
{
  packages = {
    orchard = orchardPkg;
    nixscout = nixscoutPkg;
  };
  apps = {
    orchard = {
      type = "app";
      program = "${orchardPkg}/bin/orchard";
    };
    nixscout = {
      type = "app";
      program = "${nixscoutPkg}/bin/nixscout";
    };
  };
  overlay = final: prev: {
    orchard = final.callPackage ../pkgs/orchard/default.nix { };
    nixscout = final.callPackage ../pkgs/nixscout/default.nix { };
  };
}
