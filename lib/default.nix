{ inputs, self, ... }: {
  mkHost = hostName: userName: 
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs self; }; 
      modules = [
        
        { nixpkgs.hostPlatform = "x86_64-linux"; }

        ../modules/nixos/hosts/${hostName}
        
        inputs.home-manager.nixosModules.home-manager 
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs self; };
          home-manager.users.${userName} = import ../modules/users/${userName}/home.nix;
        }
      ];
    };
}