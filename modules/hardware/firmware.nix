{ config, pkgs, ... }:

{
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.linux-firmware ];
}
