# LAN names for services that already sit behind Caddy (see caddy.nix): plain HTTP on :80.
# Pairs with adguard.nix, which resolves *.home.arpa to this server. TEMPORARY with it:
# if DNS moves to Pi-hole/Blocky/etc, only the "*.home.arpa -> server IP" record changes.
#
# Deliberately NOT proxied (same reason as caddy.nix): sonarr, radarr, bazarr, prowlarr,
# qbittorrent trust requests from localhost, which Caddy would make look local.
{ config, lib, ... }:
let
  cfg = config.modules.services.caddy;
  domain = "home.arpa";

  apps = {
    jellyfin = 8096;
    seerr = 5055;
    kavita = 5000;
    uptime = 3001;
    chat = 8082; # Open WebUI
    navidrome = 4533;
    dash = 8080; # whatever caddy.nix serves on the bare tailnet host (Homepage)
    todo = 3456; # Vikunja
    ntfy = 2586;
  };
in
{
  config = lib.mkIf cfg.enable {
    services.caddy.virtualHosts = lib.mapAttrs' (
      name: port:
      lib.nameValuePair "http://${name}.${domain}" {
        extraConfig = "reverse_proxy 127.0.0.1:${toString port}";
      }
    ) apps;

    # LAN access (caddy.nix only opens 80/443 on tailscale0).
    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
