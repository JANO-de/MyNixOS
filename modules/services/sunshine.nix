{ config, lib, pkgs, ... }:

# Sunshine — GPU screen/game streaming server. Pair with a moonlight client
# (e.g. moonlight-qt on the Surface) to use that device as an extra screen.
# On Wayland (niri on the laptop, GNOME on the desktop) capture runs through
# KMS/pipewire; first pairing is done in the web UI at http://<host>:47990.
{
  config = lib.mkIf config.modules.services.sunshine.enable {
    environment.systemPackages = [ pkgs.sunshine ];

    systemd.user.services.sunshine = {
      description = "Sunshine streaming server";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.sunshine}/bin/sunshine";
        Restart = "on-failure";
      };
    };

    # Moonlight's stream ports. Only the handful the client connects to.
    networking.firewall.allowedTCPPortRanges = [
      { from = 47984; to = 48010; }
    ];
    networking.firewall.allowedUDPPortRanges = [
      { from = 47998; to = 48010; }
    ];
  };
}