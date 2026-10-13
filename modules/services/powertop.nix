{ config, pkgs, lib, ... }:

<<<<<<< HEAD
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
=======
# powertop's automatic tuning, applied once per boot.
#
# `--auto-tune` is the cheap battery win on this hardware: it shortens the
# kernel's device autosuspend timeouts, puts the audio codec in power save and
# enables runtime PM where it is safe. It writes nothing to disk, so the tuning
# is simply re-applied on every boot.
#
# Two things this deliberately does not do:
#   - it does not tune Wi-Fi power saving. The Surface's Marvell radio drops
#     links when it is allowed to idle (see hosts/surface/hardware.nix), and a
#     flaky tablet is worse than a few percent of battery.
#   - it does not run continuously. A long-running powertop is a laptop-mode
#     battery *saver*, not a tuner, and it would fight the user's choice of
#     power profile.
{
  config = lib.mkIf config.modules.services.powertop.enable {
    systemd.services.powertop-auto-tune = {
      description = "Apply powertop's automatic power tuning";
      wantedBy = [ "multi-user.target" ];
      # Run after the host's own governor setting so the tuned value is the one
      # that sticks.
      after = [ "systemd-power-save.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${lib.getExe pkgs.powertop} --auto-tune";
      };
    };
  };
}
>>>>>>> bb95542e9e6c1400db55d062a5cf70c50aedc643
