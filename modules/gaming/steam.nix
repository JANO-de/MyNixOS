# Steam + Gamescope.
{
  config,
  lib,
  pkgs,
  ...
}:
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
    programs.steam.platformOptimizations.enable = true;
    nix.settings = {
      substituters = [ "https://nix-gaming.cachix.org" ];
      trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
    };
    environment.systemPackages = [
      pkgs.xwayland-satellite
      pkgs.vulkan-tools
    ];
  };
}
