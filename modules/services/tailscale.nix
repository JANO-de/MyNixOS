# Tailscale VPN: tailscaled as a system service.
{ config, lib, ... }:

let
  cfg = config.modules.services.tailscale;
in
{
  options.modules.services.tailscale.enable =
    lib.mkEnableOption "Tailscale (tailscaled system service; `tailscale up` works without sudo for jano)";

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true; # UDP 41641: direct connections (relays work without it)
      extraSetFlags = [ "--operator=jano" ];
    };
  };
}
