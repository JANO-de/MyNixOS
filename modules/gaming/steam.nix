# Steam + Gamescope.
{ config, lib, ... }:
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
    programs.gamescope.enable = true;
    hardware.graphics.enable32Bit = true;
  };
}
