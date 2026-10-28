# ii (ii-p3drovfx) shell module. Opt-in: modules.desktop.shell = "ii".
{ config, lib, pkgs, ... }:
let
  cfg = config.modules.desktop.ii;
in
{
  options.modules.desktop.ii.enable = lib.mkEnableOption "ii (ii-p3drovfx) Quickshell shell on Hyprland";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.ii pkgs.matugen pkgs.quickshell ];

    home-manager.users.jano.xdg.configFile."quickshell/ii".source =
      "${pkgs.ii}/share/quickshell/ii";
  };
}
