{ config, pkgs, lib, ... }:

# PowerTOP auto-tuning: applies CPU governor / WiFi PS / USB autosuspend
# tweaks at every boot. Cheap battery win on the Skylake SP5, no daemon
# footprint (one-shot per boot). Opt-in per host.
{
  config = lib.mkIf config.modules.services.powertop.enable {
    environment.systemPackages = [ pkgs.powertop ];

    systemd.services.powertop = {
      description = "PowerTOP auto-tune";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.powertop}/bin/powertop --auto-tune";
      };
    };
  };
}