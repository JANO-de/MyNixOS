# QMLCamp: static course site, nginx on loopback only. Exposed to the tailnet with:
#   sudo tailscale serve --bg --https=8443 http://127.0.0.1:8088
{ ... }:
{
  services.nginx = {
    enable = true;
    virtualHosts."qmlcamp" = {
      listen = [ { addr = "127.0.0.1"; port = 8088; } ];
      root = ./site;
      locations."/".extraConfig = "add_header Cache-Control 'no-cache';";
    };
  };
}
