# Home Manager wiring (per-user config lives in ../home.nix).
{ inputs, theme, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = null;
    extraSpecialArgs = { inherit inputs theme; };
    users.jano = import ../theme/home.nix;
  };
}
