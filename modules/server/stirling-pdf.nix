# Stirling PDF on localhost:8085 (8080 is Homepage), HTTPS via Caddy at :18085 (tailnet only).
{ config, lib, ... }:

let
  cfg = config.modules.services.stirlingPdf;
  host = "desktop.tailc8366c.ts.net";
  backend = 8085;
  port = 18085;
in
{
  options.modules.services.stirlingPdf.enable = lib.mkEnableOption "Stirling PDF";

  config = lib.mkIf cfg.enable {
    services.stirling-pdf = {
      enable = true;
      environment.SERVER_PORT = backend;
    };
    services.caddy.enable = true;
    services.caddy.virtualHosts."${host}:${toString port}".extraConfig =
      "reverse_proxy 127.0.0.1:${toString backend}";
    networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ port ];
  };
}
