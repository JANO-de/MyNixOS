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
    pkgs.callPackage ../features/orchard/pkg/default.nix { };
  niXscoutPkg = pkgs.callPackage ../features/nixscout/pkg/default.nix { };
  hyprmonPkg = pkgs.callPackage ../pkgs/hyprmon/default.nix { };
  localsendCliPkg = pkgs.callPackage ../pkgs/localsend-cli/default.nix { };
  matugenPkg = pkgs.callPackage ../pkgs/matugen/default.nix { };
in
{
  packages = {
    orchard = orchardPkg;
    niXscout = niXscoutPkg;
    hyprmon = hyprmonPkg;
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
    orchard = final.callPackage ../features/orchard/pkg/default.nix { };
    niXscout = final.callPackage ../features/nixscout/pkg/default.nix { };
    hyprmon = final.callPackage ../pkgs/hyprmon/default.nix { };
    localsend-cli = final.callPackage ../pkgs/localsend-cli/default.nix { };
    matugen = final.callPackage ../pkgs/matugen/default.nix { };
  };
}
