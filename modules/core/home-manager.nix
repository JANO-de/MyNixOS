# Home Manager wiring shared by every full host (per-user config lives in
# ../home). `niriEnabled` comes from the host's specialArgs (flake.nix);
# `tablet` toggles the touch-only parts of the niri config (modules/home/niri.nix).
{ config, inputs, niriEnabled, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs niriEnabled;
      theme = import ../theme.nix;
      tablet = false;
      gnomeEnabled = config.modules.desktop.gnome.enable;
    };
    users.jano = import ../home/default.nix;
  };
}
