# ---------------------------------------------------------------------------
# TEMPORARY: local DNS for the home network (names like jellyfin.home.arpa).
# AdGuard Home was picked because it is the easiest to start with. It can be
# swapped for Pi-hole, Blocky, dnsmasq, Technitium or the router's own DNS later:
# all that matters is that "*.home.arpa" resolves to the server's LAN IP and that
# the router hands that server out as the DNS server. Caddy does the routing.
# ---------------------------------------------------------------------------
_: {
  flake.nixosModules.server-adguard =
    _:
    let
      serverIp = "192.168.0.114"; # replaced by deploy.sh; keep it static (DHCP reservation)
      domain = "home.arpa"; # reserved for home networks (RFC 8375); avoid .home / .local
    in
    {
      services.adguardhome = {
        enable = true;
        host = "0.0.0.0";
        port = 3030; # web UI: http://<server>:3030
        openFirewall = true; # opens the web UI port
        mutableSettings = true;
        settings = {
          dns = {
            # Bind to the LAN IP only, so it does not clash with systemd-resolved's
            # stub listener on 127.0.0.53:53.
            bind_hosts = [ serverIp ];
            port = 53;
            upstream_dns = [
              "1.1.1.1"
              "9.9.9.9"
            ];
            bootstrap_dns = [
              "1.1.1.1"
              "9.9.9.9"
            ];
          };
          # One wildcard: every *.home.arpa name points at this server, Caddy routes by name.
          filtering.rewrites = [
            {
              domain = "*.${domain}";
              answer = serverIp;
              enabled = true;
            }
          ];
        };
      };

      networking.firewall.allowedTCPPorts = [ 53 ];
      networking.firewall.allowedUDPPorts = [ 53 ];
    };
}
