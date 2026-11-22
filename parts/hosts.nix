# Hosts are the folders in ./hosts. Every flake.nixosModules.* defined under parts/ goes into every host.
{
  inputs,
  self,
  lib,
  ...
}:
let
  system = "x86_64-linux";
  theme = import ../modules/theme/palette.nix;
  mkHost =
    host:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs theme; };
      modules = [
        inputs.home-manager.nixosModules.home-manager
        inputs.forge.nixosModules.default
        inputs.niri-flake.nixosModules.niri
        inputs.mangowc.nixosModules.mango
        inputs.noctalia.nixosModules.default
        inputs.stylix.nixosModules.stylix
        inputs.nix-gaming.nixosModules.platformOptimizations
        ./../hosts/${host}/default.nix
        {
          nixpkgs.overlays = [
            inputs.rust-overlay.overlays.default
            self.overlays.default
          ];
        }
        {
          imports = builtins.attrValues (
            removeAttrs self.nixosModules [
              "orchard"
              "niXscout"
              "nyaa-si"
              "neo-mangal"
            ]
          );
        }
      ];
    };
  hosts = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../hosts)
  );
in
{
  flake.nixosConfigurations = lib.genAttrs hosts mkHost;
}
