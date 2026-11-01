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
