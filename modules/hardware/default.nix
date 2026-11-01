# Hardware module aggregator. Off until a host sets modules.hardware.enable.
{ lib, ... }:
{
  options.modules.hardware.enable = lib.mkEnableOption "firmware, graphics, input and Bluetooth";

  imports = [
    ./bluetooth.nix
    ./firmware.nix
    ./drives.nix
  ];
}
