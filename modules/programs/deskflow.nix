# Deskflow server/client services.
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.programs;
in
{
  systemd.user.services.deskflow-server = lib.mkIf (cfg.deskflow.role == "server") {
    description = "Deskflow keyboard/mouse server";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.deskflow}/bin/deskflow-server -f";
      Restart = "on-failure";
    };
  };

  systemd.user.services.deskflow-client = lib.mkIf (cfg.deskflow.role == "client") {
    description = "Deskflow keyboard/mouse client";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.deskflow}/bin/deskflow-client -f --address ${cfg.deskflow.serverAddress}";
      Restart = "on-failure";
    };
  };
}
