# DankMaterialShell (Dux Shell) on Hyprland. Active when modules.dms.enable = true.
# Turns on the Dux suite apps (modules/desktop/dux/*) by default; a host can still switch one off,
# e.g. modules.dux.calendar.enable = false.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.dms;
in
{
  options.modules.dms.enable = lib.mkEnableOption "DankMaterialShell (Dux Shell) on Hyprland";

  config = lib.mkIf cfg.enable {
    programs.dank-material-shell = {
      enable = true;
      systemd.enable = true;
      # Same Qt as the rest of the system (the flake's own quickshell ships a newer Qt).
      quickshell.package = pkgs.quickshell;
    };

    programs.dux-files = {
      enable = true;
      systemd.enable = true; # start with the session
      portal.enable = true; # open/save dialogs use Dux Files
    };

    modules.dux.search.enable = lib.mkDefault true;
    modules.dux.gop.enable = lib.mkDefault true;
    modules.dux.calendar.enable = lib.mkDefault true;
  };
}
