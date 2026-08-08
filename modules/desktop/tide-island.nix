{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    quickshell
    tide-island
  ];

  systemd.user.services.tide-island = {
    description = "Tide Island Dynamic Island for Hyprland and niri";
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.tide-island}/bin/tide-island";
      Restart = "on-failure";
      RestartSec = 3;
    };
    # Disabled: replaced by end4-pC (see modules/home/end4-pc.nix). Uncomment
    # wantedBy to restore Tide Island as the autostarted shell instead.
    # wantedBy = [ "graphical-session.target" ];
  };
}
