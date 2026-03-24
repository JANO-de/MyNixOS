{ self, inputs }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  # This matches the DynamicGoose logic
  genHosts = hosts: lib.mapAttrs (name: conf: lib.nixosSystem {
    system = conf.system or "x86_64-linux";
    specialArgs = { inherit inputs self; };
    modules = [
      ../hosts/${name} # Loads hosts/desktop/default.nix or hosts/nixos/default.nix

      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs self; };
        home-manager.users.${conf.username} = {
          imports = [
            ../users/${conf.username}/home.nix
          ];
        };
      }
    ] ++ (conf.includeModules or []);
  }) hosts;

  # Helper for development shells (if you use them)
  eachSystem = lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
  pkgsFor = system: import inputs.nixpkgs { inherit system; config.allowUnfree = true; };
}
