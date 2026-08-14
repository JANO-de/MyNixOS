{
  description = "MyNixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Noctalia shell — pin to the "cachix" branch, which always points to the
    # latest commit with prebuilt binaries on https://noctalia.cachix.org
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
  
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, noctalia, zen-browser }@inputs:
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
