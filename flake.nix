{
  description = "Jano's Modular NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    
    # Auto-import 
    haumea.url = "github:nix-community/haumea/v0.2.2";
    haumea.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, haumea, ... }@inputs:
  let
    # Función para cargar hosts
    mkHost = hostName: { username, userDescription }: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit self inputs username userDescription; };
      modules = [
        # Carga el default.nix de la carpeta del host (desktop o laptop) 
        ./hosts/${hostName}/default.nix
        
        # Auto-importar TODO lo que esté en /modules/core/ 
        (haumea.lib.load {
          src = ./modules/core;
          loader = haumea.lib.loaders.default;
        })

        inputs.home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit self inputs; };
          home-manager.users.${username} = import ./users/${username}/home.nix;
        }
      ];
    };
  in {
    nixosConfigurations = {
      desktop = mkHost "desktop" { username = "jano"; userDescription = "Jano's Desktop"; };
      laptop = mkHost "laptop" { username = "jano"; userDescription = "Jano's Laptop"; };
    };
  };
}