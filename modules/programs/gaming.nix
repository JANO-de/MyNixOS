{ config, pkgs, lib, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = config.modules.programs.gaming.enable;
  };

  programs.gamemode.enable = config.modules.programs.gaming.enable;
  programs.steam = {
    enable = config.modules.programs.gaming.enable;
    remotePlay.openFirewall = config.modules.programs.gaming.enable; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = config.modules.programs.gaming.enable; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = config.modules.programs.gaming.enable; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  # Force Steam's desktop UI to 1.5x scale under XWayland/xwayland-satellite,
  # which otherwise keeps ~1x UI on the 4K@1.5 monitor (mixed-DPI setup).
  # This env var only affects the Steam client UI, never games.
  environment.sessionVariables = lib.mkIf config.modules.programs.gaming.enable {
    STEAM_FORCE_DESKTOPUI_SCALING = "1.5";
  };

  environment.systemPackages = lib.optionals config.modules.programs.gaming.enable (with pkgs; [
    (prismlauncher.overrideAttrs (old: {
      preFixup = (old.preFixup or "") + ''
        gappsWrapperArgs+=(
          --set DRI_PRIME 1
        )
      '';
    }))
    gamescope
    bazaar
    heroic
    waydroid
    waydroid-helper
    steamcmd
    ftb-app
  ]);
}