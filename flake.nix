{
  description = "Jano's Modular NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
    
    import-tree.url = "github:vic/import-tree";
    flake-parts.url = "github:hercules-ci/flake-parts";
  
    nix-gaming.url = "github:fufexan/nix-gaming";

    matugen.url = "github:/InioX/Matugen";

    ags.url = "github:Aylur/ags";
    astal.url = "github:Aylur/astal";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake 
    { inherit inputs; }
    (inputs.import-tree ./modules);
}
