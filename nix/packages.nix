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
  niXscoutPkg = pkgs.callPackage ../pkgs/niXscout/default.nix { };
  iiPkg = pkgs.callPackage ../pkgs/ii-p3drovfx/default.nix { };
  iiVynxPkg = pkgs.callPackage ../pkgs/ii-vynx/default.nix { };
  hyprmonPkg = pkgs.callPackage ../pkgs/hyprmon/default.nix { };
  localsendCliPkg = pkgs.callPackage ../pkgs/localsend-cli/default.nix { };
  matugenPkg = pkgs.callPackage ../pkgs/matugen/default.nix { };
in
{
  packages = {
    orchard = orchardPkg;
    niXscout = niXscoutPkg;
    ii = iiPkg;
    ii-vynx = iiVynxPkg;
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
    ii = {
      type = "app";
      program = "${pkgs.quickshell}/bin/quickshell";
    };
  };
  overlay = final: prev: {
    orchard = final.callPackage ../pkgs/orchard/default.nix { };
    niXscout = final.callPackage ../pkgs/niXscout/default.nix { };
    ii = final.callPackage ../pkgs/ii-p3drovfx/default.nix { };
    ii-vynx = final.callPackage ../pkgs/ii-vynx/default.nix { };
    hyprmon = final.callPackage ../pkgs/hyprmon/default.nix { };
    localsend-cli = final.callPackage ../pkgs/localsend-cli/default.nix { };
    matugen = final.callPackage ../pkgs/matugen/default.nix { };
  };
}
