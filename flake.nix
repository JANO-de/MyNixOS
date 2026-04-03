{
  description = "Jano's Modular NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
    
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    
    import-tree.url = "github:vic/import-tree";

    flake-parts.url = "github:hercules-ci/flake-parts";
  
    nix-gaming.url = "github:fufexan/nix-gaming";

    matugen.url = "github:/InioX/Matugen";

    stylix.url = "github:danth/stylix";

    ags.url = "github:Aylur/ags";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake 
    { inherit inputs; }
    (inputs.import-tree ./modules);
}
