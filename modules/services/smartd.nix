# smartd: background SMART polling.
{ config, lib, ... }:

let
  cfg = config.modules.services.smartd;
in
{
  options.modules.services.smartd.enable =
    lib.mkEnableOption "smartd, background SMART polling with journal and desktop notifications";

  config = lib.mkIf cfg.enable {
    services.smartd = {
      enable = true;
      autodetect = true;
      notifications.systembus-notify.enable = true;
    };
  };
}
