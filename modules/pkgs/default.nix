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
    pkgs.callPackage ../programs/orchard/pkg/default.nix { };
  niXscoutPkg = pkgs.callPackage ../programs/nixscout/pkg/default.nix { };
  localsendCliPkg = pkgs.callPackage ./localsend-cli/default.nix { };
  matugenPkg = pkgs.callPackage ./matugen/default.nix { };
in
{
  packages = {
    orchard = orchardPkg;
    niXscout = niXscoutPkg;
    localsend-cli = localsendCliPkg;
    matugen = matugenPkg;
  };
  apps = {
    orchard = {
      type = "app";
      program = "${orchardPkg}/bin/orchard";
    };
    niXscout = {
      type = "app";
      program = "${niXscoutPkg}/bin/niXscout";
    };
  };
  overlay = final: prev: {
    orchard = final.callPackage ../programs/orchard/pkg/default.nix { };
    niXscout = final.callPackage ../programs/nixscout/pkg/default.nix { };
    localsend-cli = final.callPackage ./localsend-cli/default.nix { };
    matugen = final.callPackage ./matugen/default.nix { };
  };
}
