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
    {
      self,
      nixpkgs,
      ...
    }@inputs:
  let
    lib = import ./lib {
      inherit self inputs;
    };
  in
  {
    nixosConfigurations = lib.genHosts {
      # Change 'desktop-gezaa' to your hostname
      desktop = {
        username = "jano";
        userDescription = "Jano's desktop";
        # If their lib supports it, you'd point to your specific laptop folder here
      };

      laptop = {
        username = "jano";
        userDescription = "Jano's laptop";
      };
    };
  };
}
