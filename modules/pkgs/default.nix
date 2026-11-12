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
  nyaaSiPkg = pkgs.callPackage ../programs/nyaa-si/pkg/default.nix { src = inputs.nyaa-si-src; };
  neoMangalPkg = pkgs.callPackage ../programs/neo-mangal/pkg/default.nix {
    src = inputs.neo-mangal-src;
  };
  vidDlPkg = pkgs.callPackage ../programs/vid-dl/pkg/default.nix { };
  localsendCliPkg = pkgs.callPackage ./localsend-cli/default.nix { };
  matugenPkg = pkgs.callPackage ./matugen/default.nix { };
in
{
  packages = {
    orchard = orchardPkg;
    niXscout = niXscoutPkg;
    nyaa-si = nyaaSiPkg;
    neo-mangal = neoMangalPkg;
    vid-dl = vidDlPkg;
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
    nyaa-si = {
      type = "app";
      program = "${nyaaSiPkg}/bin/nyaa-si";
    };
    neo-mangal = {
      type = "app";
      program = "${neoMangalPkg}/bin/neo-mangal";
    };
  };
  overlay = final: prev: {
    orchard = final.callPackage ../programs/orchard/pkg/default.nix { };
    niXscout = final.callPackage ../programs/nixscout/pkg/default.nix { };
    nyaa-si = final.callPackage ../programs/nyaa-si/pkg/default.nix { src = inputs.nyaa-si-src; };
    neo-mangal = final.callPackage ../programs/neo-mangal/pkg/default.nix {
      src = inputs.neo-mangal-src;
    };
    vid-dl = final.callPackage ../programs/vid-dl/pkg/default.nix { };
    localsend-cli = final.callPackage ./localsend-cli/default.nix { };
    matugen = final.callPackage ./matugen/default.nix { };
  };
}
