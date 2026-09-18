{ config, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.gamemode.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  # Force Steam's desktop UI to 1.5x scale under XWayland/xwayland-satellite,
  # which otherwise keeps ~1x UI on the 4K@1.5 monitor (mixed-DPI setup).
  # This env var only affects the Steam client UI, never games.
  environment.sessionVariables.STEAM_FORCE_DESKTOPUI_SCALING = "1.5";


  environment.systemPackages = with pkgs; [
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
    steamcmd
    ftb-app
  ];
}
