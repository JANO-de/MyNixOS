# Laptop: Intel + NVIDIA (PRIME offload), stock kernel (CachyOS: modules.hardware.cachyos.enable, off).
# Hyprland + immaterial-impulse.
{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  networking.hostName = "laptop";

  modules.hardware.enable = true;
  modules.hardware.nvidia.enable = true;
  modules.services.enable = true;
  modules.services.qmk.enable = true;
  modules.services.virtualbox.enable = true;
  modules.services.tailscale.enable = true;
  modules.theme.enable = true;
  modules.programs.enable = true;
  modules.desktop.enable = true;
  modules.scripts.all = true;

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
  modules.imi.enable = false;
  modules.dms.enable = true;
  modules.dux.greeter.enable = true;
  modules.artcraft.enable = true;
  modules.desktop.drmDevices = "/dev/dri/igpu:/dev/dri/dgpu";
  modules.desktop.dotfiles.enable = true;

  system.stateVersion = "26.05";
}
