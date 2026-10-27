# Home Manager wiring (per-user config lives in ../home.nix).
{ inputs, theme, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs theme; };
    users.jano = import ../home.nix;
  };
}
