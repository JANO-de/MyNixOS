{
  inputs,
  system,
  theme,
}:
{
  host,
  cachyos ? false,
}:
let
  inherit (inputs)
    nixpkgs
    home-manager
    mango
    forge
    nix-cachyos-kernel
    self
    ;
in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs theme; };
  modules = [
    home-manager.nixosModules.home-manager
    forge.nixosModules.default
    mango.nixosModules.mango
    ../hosts/${host}/default.nix
  ]
  ++ nixpkgs.lib.optional cachyos {
    nixpkgs.overlays = [ nix-cachyos-kernel.overlays.pinned ];
  }
  ++ [
    {
      nixpkgs.overlays = [
        inputs.rust-overlay.overlays.default
        self.overlays.default
      ];
    }
  ];
}
