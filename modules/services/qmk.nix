# QMK/Keychron keyboards (Via/Vial/Launcher access without root).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.services.qmk;
in
{
  options.modules.services.qmk.enable =
    lib.mkEnableOption "QMK/Keychron keyboard access (Via/Vial/Launcher without root)";

  config = lib.mkIf cfg.enable {
    hardware.keyboard.qmk = {
      enable = true;
      keychronSupport = true;
    };
    services.udev.packages = [ pkgs.qmk-udev-rules ];
    services.udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", TAG+="uaccess"
    '';
  };
}
