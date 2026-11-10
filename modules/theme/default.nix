# Theme: Home Manager config for user jano (GTK, Qt).
# palette.nix is plain data: flake.nix imports it by path and passes it to
# every module as `theme`. gtk-qt.nix and home.nix are Home
# Manager modules, so only this file is a NixOS module.
{ config, lib, ... }:

{
  options.modules.theme.enable = lib.mkEnableOption "Home Manager theming (GTK, Qt)";

  config = lib.mkIf config.modules.theme.enable {
    home-manager.users.jano = import ./home.nix;
  };
}
