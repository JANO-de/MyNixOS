{ config, lib, pkgs, ... }:

{
  services.xserver.enable = true;
  services.displayManager.sddm = lib.mkIf config.modules.desktop.plasma.enable {
    enable = true;
    theme = "${pkgs.catppuccin-sddm}/share/sddm/themes/catppuccin-mocha-mauve";
  };
  services.desktopManager.plasma6.enable = config.modules.desktop.plasma.enable;
}
