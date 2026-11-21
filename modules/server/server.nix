# modules.server.enable turns on every home-server service. Tailscale is NOT
# included (laptop uses it too): enable modules.services.tailscale on the host.
{ config, lib, ... }:

{
  options.modules.server.enable = lib.mkEnableOption "all home-server services (media, apps, proxy, monitoring)";

  config = lib.mkIf config.modules.server.enable {
    assertions = [
      {
        assertion = config.modules.services.tailscale.enable;
        message = "modules.server.enable needs modules.services.tailscale.enable (Caddy certificates and firewall use it).";
      }
    ];

    modules.services = {
      jellyfin.enable = lib.mkDefault true;
      mediaStack.enable = lib.mkDefault true;
      mediaTracker.enable = lib.mkDefault true;
      kavita.enable = lib.mkDefault true;
      homepage.enable = lib.mkDefault true;
      uptimeKuma.enable = lib.mkDefault true;
      openWebui.enable = lib.mkDefault true;
      caddy.enable = lib.mkDefault true;
      openwa.enable = lib.mkDefault true;
      freshrss.enable = lib.mkDefault true;
      itTools.enable = lib.mkDefault true;
      stirlingPdf.enable = lib.mkDefault true;
      books.enable = lib.mkDefault true;
    };
  };
}
