{
  description = "MyNixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager }@inputs:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    theme = import ./modules/theme.nix;
  in
  {
    nixosConfigurations = {
      laptop = lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs theme; };
        modules = [
          inputs.home-manager.nixosModules.home-manager
          ./hosts/laptop/default.nix
        ];
      };
    };
  };
}
