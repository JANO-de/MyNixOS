{
  description = "MyNixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tide-island = {
      url = "github:enhaoswen/Tide-island/1.0.35";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, tide-island }@inputs:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    theme = import ./modules/theme.nix;
  in
  {
    overlays.default = final: prev: {
      tide-island = final.callPackage ./pkgs/tide-island { src = tide-island; inherit theme; };
    };

    nixosConfigurations = {
      laptop = lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs theme; };
        modules = [
          inputs.home-manager.nixosModules.home-manager
          ({ pkgs, ... }: { nixpkgs.overlays = [ self.overlays.default ]; })
          ./hosts/laptop/default.nix
        ];
      };
    };
  };
}
