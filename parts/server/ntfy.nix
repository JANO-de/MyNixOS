# ntfy: self-hosted push notifications, served on http://ntfy.home.arpa via caddy-lan.nix.
# Also reachable over Tailscale on :2586 so the phone app works away from home.
_: {
  flake.nixosModules.server-ntfy = _: {
    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = "http://ntfy.home.arpa";
        listen-http = ":2586";
        behind-proxy = true;
      };
    };

    networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 2586 ];
  };
}
