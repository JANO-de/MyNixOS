{
  description = "Jano's Modular NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
    
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    
    import-tree.url = "github:vic/import-tree";

    flake-parts.url = "github:hercules-ci/flake-parts";
  
    nix-gaming.url = "github:fufexan/nix-gaming";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      # 1. Automatically import everything in modules/parts
      imports = [
        (inputs.import-tree ./modules/parts)
      ];

      # 2. Define your hosts using your custom lib
      flake = { self, ...}: let
        myLib = import ./lib { inherit inputs self; };
      in {
        nixosConfigurations = {
          desktop = myLib.mkHost "desktop" "jano";
          laptop  = myLib.mkHost "laptop"  "jano";
        };
      };
    };
}
