# Bluetooth.
{ config, lib, ... }:

{
  config = lib.mkIf config.modules.hardware.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General = {
        Experimental = true;
        ControllerMode = "dual";
      };
    };
  };
}
