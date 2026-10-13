{ config, lib, pkgs, ... }:

# Waydroid — Android inside a container, rendered onto the Wayland session.
#
# The nftables variant frees the container from needing the host user to own
# /dev nodes and iptables chains; the init script brings the network/service
# bridge up itself. Start it with `waydroid session start` once logged into a
# Wayland desktop, then `waydroid show-full-ui`.
{
  config = lib.mkIf config.modules.services.waydroid.enable {
    virtualisation.waydroid.enable = true;
    virtualisation.waydroid.package = pkgs.waydroid-nftables;
  };
}