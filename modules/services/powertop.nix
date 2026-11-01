# powertop: automatic power tuning once per boot.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.services.powertop;
in
{
  options.modules.services.powertop.enable =
    lib.mkEnableOption "powertop --auto-tune once per boot (leaves Wi-Fi power saving alone, see hosts/halos1)";

  config = lib.mkIf cfg.enable {
    systemd.services.powertop-auto-tune = {
      description = "Apply powertop's automatic power tuning";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-power-save.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${lib.getExe pkgs.powertop} --auto-tune";
      };
    };
  };
}
