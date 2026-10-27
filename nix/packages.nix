{ inputs, system }:
let
  inherit (inputs) nixpkgs self;
  orchardPkg =
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ inputs.rust-overlay.overlays.default ];
        config.allowUnfree = true;
      };
    in
    pkgs.callPackage ../pkgs/orchard/default.nix { };
in
{
  packages = {
    orchard = orchardPkg;
  };
  apps = {
    orchard = {
      type = "app";
      program = "${orchardPkg}/bin/orchard";
    };
  };
  overlay = final: prev: {
    orchard = final.callPackage ../pkgs/orchard/default.nix { };
  };
}
