# FreshRSS: RSS reader. Caddy vhost https://\<host\>:18087 (tailnet only).
# Login password: put it in /var/lib/freshrss-password (file is created empty, owned by freshrss).
{ ... }:
{
  flake.nixosModules.server-freshrss =
    { config, lib, ... }:

    let
      cfg = config.modules.services.freshrss;
      host = "desktop.tailc8366c.ts.net";
      port = 18087;
    in
    {
      options.modules.services.freshrss.enable = lib.mkEnableOption "FreshRSS";

      config = lib.mkIf cfg.enable {
        services.freshrss = {
          enable = true;
          webserver = "caddy";
          virtualHost = "${host}:${toString port}";
          baseUrl = "https://${host}:${toString port}";
          authType = "form";
          defaultUser = "jano";
          passwordFile = "/var/lib/freshrss-password";
        };
        systemd.tmpfiles.rules = [ "f /var/lib/freshrss-password 0600 freshrss freshrss -" ];
        networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ port ];
      };
    };
}
