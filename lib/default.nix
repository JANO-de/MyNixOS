{ inputs, ... }: {
  mkHost = hostName: userName: 
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        # Path to the hardware/configuration for this specific host
        ../modules/hosts/${hostName}
        
        # Load Home Manager
        inputs.home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.${userName} = import ../modules/users/${userName}/home.nix;
        }
      ];
    };
}