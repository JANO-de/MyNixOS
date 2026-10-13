# Generic hardware bits every host gets: bluetooth, firmware, libinput.
{ pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      Experimental = true;
      ControllerMode = "dual";
    };
  };

  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.linux-firmware ];

  services.libinput.enable = true;
}
