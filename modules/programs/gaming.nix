{ config, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.gamemode.enable = true;
  programs.steam.enable = true;

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
    steamcmd
  ];
}
