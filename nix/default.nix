inputs:
let
  system = "x86_64-linux";
  hosts = import ./hosts.nix { inherit inputs system; };
  pkgsOut = import ./packages.nix { inherit inputs system; };
  dev = import ./dev.nix { inherit inputs system; };
in
{
  packages.${system} = pkgsOut.packages;
  apps.${system} = pkgsOut.apps;
  overlays.default = pkgsOut.overlay;
  nixosModules.orchard = ../modules/programs/orchard.nix;
  nixosModules.niXscout = ../modules/programs/niXscout.nix;
  nixosConfigurations = hosts;
  devShells.${system} = dev.shells;
  formatter.${system} = dev.formatter;
  checks.${system} = dev.checks;
}
