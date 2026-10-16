{ config, pkgs, ... }:

{
  hardware.keyboard.qmk = {
    enable = true;
    keychronSupport = true;
  };

  services.udev.packages = with pkgs; [
    qmk-udev-rules
  ];

  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", TAG+="uaccess"
  '';
}