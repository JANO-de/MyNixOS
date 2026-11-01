# Laptop: Intel + NVIDIA (PRIME offload), stock kernel (CachyOS: `cachyos` flag in nix/hosts.nix, off).
# Hyprland + ii (variant vynx).
{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/base/core
    ../../profiles/base/hardware
    ../../profiles/base/services
    ../../features/programs
    ../../features/desktop
    ../../features
  ];

  networking.hostName = "laptop";

  # The Surface acts as an extra monitor via this sunshine server + moonlight.
  modules.services.sunshine.enable = true;

  # Deskflow: this machine serves the keyboard/mouse; desktop and halos1 join.
  modules.programs.deskflow.role = "server";

  programs.orchard.enable = true;
  programs.niXscout.enable = true;
  networking.firewall.allowedTCPPorts = [ 24800 ];

  # Hybrid graphics (Intel iGPU + RTX 3050): PRIME offload.
  hardware.nvidia.prime = {
    offload.enable = true;
    offload.enableOffloadCmd = true;
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  modules.desktop.session = "hyprland";
  modules.desktop.shell = "immaterial";
  modules.desktop.immaterial.enable = true;
  modules.desktop.drmDevices = "/dev/dri/igpu:/dev/dri/dgpu";
  modules.desktop.dotfiles.enable = true;

  system.stateVersion = "26.05";
}
