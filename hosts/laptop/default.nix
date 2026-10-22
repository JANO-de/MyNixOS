# Laptop: Intel + NVIDIA, CachyOS kernel (see flake.nix). mango + dynisland.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core.nix
    ../../modules/hardware.nix
    ../../modules/services.nix
    ../../modules/programs.nix
    ../../modules/desktop
    ../../modules/extras/xampp.nix # XAMPP workbench (/opt/lampp) lives only here
  ];

  networking.hostName = "laptop";
  modules.hardware.elementsDrive.enable = true;

  # The Surface acts as an extra monitor via this sunshine server + moonlight.
  modules.services.sunshine.enable = true;

  # Deskflow: this machine serves the keyboard/mouse; desktop and surface join.
  modules.programs.deskflow.role = "server";
  networking.firewall.allowedTCPPorts = [ 24800 ];

  system.stateVersion = "26.05";
}
