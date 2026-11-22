# Networking: NetworkManager, firewall, reverse-path.
# Nothing is opened on every interface any more: services open their own ports on
# tailscale0 only (see media-stack.nix, homepage.nix, caddy.nix). Jellyfin and
# Sunshine still open theirs themselves.
{ ... }:
{
  flake.nixosModules.services-networking =
    { config, lib, ... }:

    {
      config = lib.mkIf config.modules.services.enable {
        networking.networkmanager.enable = true;
        networking.firewall = {
          enable = true;
          # "loose" is what Tailscale needs; `false` switched reverse-path filtering off entirely.
          checkReversePath = "loose";
        };
      };
    };
}
