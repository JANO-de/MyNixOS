# Home Manager wiring (per-user config comes from modules/theme).
{ inputs, theme, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = null;
    extraSpecialArgs = { inherit inputs theme; };
  };
}
