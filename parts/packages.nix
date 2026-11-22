# Packages, apps and the overlay. The package definitions are plain callPackage files in ../pkgs.
{ inputs, ... }:
{
  flake.overlays.default = import ../pkgs/overlay.nix inputs;

  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs { inherit system; };
      # Orchard needs the Rust toolchain overlay (>= 1.96) and unfree allowed.
      rustPkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.rust-overlay.overlays.default ];
        config.allowUnfree = true;
      };

      orchard = rustPkgs.callPackage ../pkgs/orchard { };
      niXscout = pkgs.callPackage ../pkgs/nixscout { };
      nyaa-si = pkgs.callPackage ../pkgs/nyaa-si { src = inputs.nyaa-si-src; };
      neo-mangal = pkgs.callPackage ../pkgs/neo-mangal { src = inputs.neo-mangal-src; };
      vid-dl = pkgs.callPackage ../pkgs/vid-dl { };
      localsend-cli = pkgs.callPackage ../pkgs/localsend-cli { };
      matugen = pkgs.callPackage ../pkgs/matugen { };
    in
    {
      packages = {
        inherit
          orchard
          niXscout
          nyaa-si
          neo-mangal
          vid-dl
          localsend-cli
          matugen
          ;
      };

      apps = {
        orchard = {
          type = "app";
          program = "${orchard}/bin/orchard";
        };
        niXscout = {
          type = "app";
          program = "${niXscout}/bin/niXscout";
        };
        nyaa-si = {
          type = "app";
          program = "${nyaa-si}/bin/nyaa-si";
        };
        neo-mangal = {
          type = "app";
          program = "${neo-mangal}/bin/neo-mangal";
        };
      };
    };
}
