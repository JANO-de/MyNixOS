# Laptop: Intel + NVIDIA (PRIME offload), stock kernel (CachyOS: `cachyos` flag in nix/hosts.nix, off).
# Hyprland + ii (variant vynx).
{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
    ../../modules/hardware
    ../../modules/services
    ../../modules/programs
    ../../modules/programs/orchard.nix
    ../../modules/desktop
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
  modules.desktop.shell = "ii";
  modules.desktop.ii.enable = true;
  modules.desktop.drmDevices = "/dev/dri/igpu:/dev/dri/dgpu";
  modules.desktop.dotfiles.enable = true;

  # Legacy: only read by the mango session (remove together with mango).
  modules.desktop.mango.monitorRules = [
    "name:^eDP-1,width:1080,height:1920,refresh:60,x:1920,y:0,rr:0"
    "name:^HDMI-A-1,width:1080,height:1920,refresh:60,x:,y:0,rr:0"
  ];

  # ii fork: vynx, with its own dotfiles folder (keeps p3drovfx config apart).
  modules.desktop.ii.variant = "vynx";
  modules.desktop.dotfiles.host = "laptop-vynx";

  system.stateVersion = "26.05";
}
