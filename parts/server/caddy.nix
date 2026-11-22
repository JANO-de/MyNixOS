# Caddy: HTTPS in front of the apps that have their own login, tailnet only.
#   https://<host>/          -> Homepage
#   https://<host>:<port+10000> -> each app below (Jellyfin 8096 -> :18096)
# Certificates come from Tailscale (needs "HTTPS Certificates" enabled in the Tailscale
# admin console, DNS page). Sonarr/Radarr/Lidarr/Prowlarr/Bazarr/qBittorrent are NOT
# proxied: they trust requests from localhost, which would bypass their login.
_: {
  flake.nixosModules.server-caddy =
    { config, lib, ... }:

    let
      cfg = config.modules.services.caddy;
      host = "desktop.tailc8366c.ts.net";
      offset = 10000;

      apps = {
        jellyfin = 8096;
        seerr = 5055;
        kavita = 5000;
        uptime-kuma = 3001;
        open-webui = 8082;
      };

      site = port: { extraConfig = "reverse_proxy 127.0.0.1:${toString port}"; };
    in
    {
      options.modules.services.caddy.enable =
        lib.mkEnableOption "Caddy HTTPS reverse proxy (tailnet only)";

      config = lib.mkIf cfg.enable {
        # Let Caddy fetch the *.ts.net certificate from tailscaled.
        services.tailscale.permitCertUid = "caddy";

        services.caddy = {
          enable = true;
          virtualHosts = {
            "${host}" = site 8080;
          }
          // lib.mapAttrs' (
            _: port: lib.nameValuePair "${host}:${toString (port + offset)}" (site port)
          ) apps;
        };

        networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
          80
          443
        ]
        ++ map (port: port + offset) (lib.attrValues apps);
      };
    };
}
