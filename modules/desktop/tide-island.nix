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
    wantedBy = [ "graphical-session.target" ];
  };
}
