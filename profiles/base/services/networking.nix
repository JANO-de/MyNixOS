# Networking: NetworkManager, firewall, reverse-path.
{ ... }:

{
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPortRanges = [
      { from = 4000; to = 4007; }
      { from = 8000; to = 8010; }
    ];
  };
  networking.firewall.checkReversePath = false;
}
