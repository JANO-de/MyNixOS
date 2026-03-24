{
  description = "Jano's Modular NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
    noctalia.url = "github:noctalia-dev/noctalia-shell";

  };

  outputs =
    { self, nixpkgs, ... }@inputs:
  let
    lib = import ./lib {
      inherit self inputs;
    };
  in
  {
    nixosConfigurations = lib.genHosts {
      desktop = {
        username = "jano";
        userDescription = "Jano's desktop";
      };

      laptop = {
        username = "jano";
        userDescription = "Jano's laptop";
      };

    };
  };
}
