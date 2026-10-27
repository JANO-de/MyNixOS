# Firmware, graphics, input.
{ pkgs, ... }:

{
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.linux-firmware ];

  services.libinput.enable = true;
  hardware.graphics.enable = true;
}
