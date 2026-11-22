# Packages, apps, overlay, dev shell, formatter, checks and the exported modules.
{ inputs, self, ... }:
let
  system = "x86_64-linux";
  pkgsOut = import ../modules/pkgs { inherit inputs system; };
  dev = import ../modules/pkgs/dev.nix { inherit inputs system self; };
in
{
  flake = {
    packages.${system} = pkgsOut.packages;
    apps.${system} = pkgsOut.apps;
    overlays.default = pkgsOut.overlay;
    nixosModules = {
      orchard = ../modules/programs/orchard/default.nix;
      niXscout = ../modules/programs/nixscout/default.nix;
      nyaa-si = ../modules/programs/nyaa-si/default.nix;
      neo-mangal = ../modules/programs/neo-mangal/default.nix;
    };
    devShells.${system} = dev.shells;
    formatter.${system} = dev.formatter;
    checks.${system} = dev.checks;
  };
}
