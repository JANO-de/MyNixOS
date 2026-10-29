# Deskflow server/client services (deskflow >= 1.2x: single `deskflow-core <server|client>` binary).
# Screen layout / server address live in Deskflow's own settings (configure once in the `deskflow` GUI).
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.programs;
  mkService = mode: {
    description = "Deskflow keyboard/mouse ${mode}";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.deskflow}/bin/deskflow-core ${mode}";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
in
{
  systemd.user.services.deskflow-server = lib.mkIf (cfg.deskflow.role == "server") (mkService "server");
  systemd.user.services.deskflow-client = lib.mkIf (cfg.deskflow.role == "client") (mkService "client");
}
