{ config, pkgs, lib, ... }:

# Deskflow — share one keyboard and mouse between machines (Barrier/Synergy
# successor, Wayland-capable via libei). Every host gets the binaries; the
# `role` option decides whether a machine *serves* its keyboard/mouse or
# *consumes* another server's, with a ready systemd user service for each.
# Default role is "none" so hosts just have the package; flip e.g.
# laptop as server (role = "server") and the Surface as a client
# (role = "client", serverAddress = "laptop").
{
  config = lib.mkIf config.modules.programs.deskflow.enable {
    environment.systemPackages = [ pkgs.deskflow ];

    systemd.user.services.deskflow-server = lib.mkIf (config.modules.programs.deskflow.role == "server") {
      description = "Deskflow keyboard/mouse server";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.deskflow}/bin/deskflow-server -f";
        Restart = "on-failure";
      };
    };

    systemd.user.services.deskflow-client = lib.mkIf (config.modules.programs.deskflow.role == "client") {
      description = "Deskflow keyboard/mouse client";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.deskflow}/bin/deskflow-client -f --address ${config.modules.programs.deskflow.serverAddress}";
        Restart = "on-failure";
      };
    };
  };
}