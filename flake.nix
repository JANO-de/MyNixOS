{
  description = "MyNixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    inir.url = "github:snowarch/inir";

    opencode-flake.url = "github:noblepayne/opencode-flake";

    # CachyOS kernel — release branch = CI-built & cached on their Attic.
    # Do NOT override its nixpkgs input (patches/kernel must stay in sync).
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  nixConfig = {
    extra-substituters = [
      "https://attic.xuyh0120.win/lantian"
    ];
    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, zen-browser, nix-cachyos-kernel, opencode-flake, inir }@inputs:
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
          # CachyOS kernel overlay (pinned = built against their nixpkgs, uses binary cache)
          ({ ... }: { nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ]; })
          ./hosts/laptop/default.nix
        ];
      };
    };
  };
}
