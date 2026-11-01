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
  theme = import ../profiles/base/theme/palette.nix;
  mkHost = import ../lib/mkHost.nix { inherit inputs system theme; };
in
{
  desktop = mkHost { host = "desktop"; };
  laptop = mkHost {
    host = "laptop";
    cachyos = false;
  };
  halos1 = mkHost { host = "halos1"; };
}
