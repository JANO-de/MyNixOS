# Uptime Kuma: pings/monitors your services and alerts you when one goes down.
# Listens on localhost only; reach it through Caddy at https://<tailnet-name>:13001.
{ ... }:
{
  flake.nixosModules.server-uptime-kuma =
    { config, lib, ... }:

    let
      cfg = config.modules.services.uptimeKuma;
    in
    {
      options.modules.services.uptimeKuma.enable = lib.mkEnableOption "Uptime Kuma monitoring";

      config = lib.mkIf cfg.enable {
        services.uptime-kuma = {
          enable = true;
          settings = {
            HOST = "127.0.0.1";
            PORT = "3001";
          };
        };
      };
    };
}
