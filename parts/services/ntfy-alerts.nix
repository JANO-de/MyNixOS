# Push a notification to ntfy when a systemd unit fails or smartd reports a disk problem.
# Attach to a unit with: unitConfig.OnFailure = "ntfy-failure@%n.service";
_: {
  flake.nixosModules.services-ntfy-alerts =
    { pkgs, ... }:
    {
      systemd.services."ntfy-failure@" = {
        description = "Notify ntfy that %i failed";
        serviceConfig.Type = "oneshot";
        scriptArgs = "%i";
        script = ''
          ${pkgs.curl}/bin/curl -s -H "Title: $1 failed" -H "Priority: high" -H "Tags: warning" \
            -d "See: journalctl -u $1" http://127.0.0.1:2586/homelab
        '';
      };

      systemd.services.restic-backups-server.unitConfig.OnFailure = "ntfy-failure@%n.service";

      # smartd disk warnings -> ntfy (replaces the default notifier on the DEVICESCAN line).
      services.smartd.defaults.autodetected =
        let
          notify = pkgs.writeShellScript "smartd-ntfy" ''
            ${pkgs.curl}/bin/curl -s -H "Title: Disk warning: $SMARTD_DEVICE" -H "Priority: urgent" -H "Tags: rotating_light" \
              -d "$SMARTD_FAILTYPE: $SMARTD_MESSAGE" http://127.0.0.1:2586/homelab
          '';
        in
        "-a -m <nomailer> -M exec ${notify}";
    };
}
