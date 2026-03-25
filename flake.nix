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

  outputs = inputs: inputs.flake-parts.lib.mkFlake
    { 
      systems = [ "x86_64-linux" ];  
      inherit inputs; 
    }
    (inputs.import-tree ./modules);
}
