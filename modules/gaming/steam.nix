# Steam + Gamescope.
{ config, lib, pkgs, ... }:
let
  cfg = config.modules.gaming.steam;
in
{
  options.modules.gaming.steam = lib.mkEnableOption "Steam";

  config = lib.mkIf cfg {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
    };
    programs.gamescope = {
      enable = true;
      capSysNice = true;
    };
    hardware.graphics.enable32Bit = true;
    environment.systemPackages = [
      pkgs.xwayland-satellite
      pkgs.vulkan-tools
    ];
  };
}
