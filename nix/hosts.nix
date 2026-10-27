{ inputs, system }:
let
  inherit (inputs)
    nixpkgs
    home-manager
    mango
    forge
    nix-cachyos-kernel
    self
    ;
  theme = import ../modules/theme/palette.nix;

  mkHost =
    {
      host,
      cachyos ? false,
    }:
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
    };
in
{
  desktop = mkHost { host = "desktop"; };
  laptop = mkHost {
    host = "laptop";
    cachyos = true;
  };
  halos1 = mkHost { host = "halos1"; };
}
