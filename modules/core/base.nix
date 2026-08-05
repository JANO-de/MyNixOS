{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  programs.mtr.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  zramSwap.enable = true;

  swapDevices = [ { device = "/swapfile"; size = 8192; } ];
}
