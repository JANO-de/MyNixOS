# Hardware switch: modules.hardware.enable. Off until a host sets it.
# The features (bluetooth, firmware, nvidia, ...) are their own modules in this folder.
{ ... }:
{
  flake.nixosModules.hardware =
    { lib, ... }:
    {
      options.modules.hardware.enable = lib.mkEnableOption "firmware, graphics, input and Bluetooth";
    };
}
