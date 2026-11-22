# Laptop: Intel + NVIDIA (PRIME offload), stock kernel (CachyOS: modules.hardware.cachyos.enable, off).
# niri + Noctalia.
{ self, ... }:
{
  flake.nixosModules.host-laptop =
    { pkgs, ... }:

    {

      networking.hostName = "laptop";

      modules.hardware.enable = true;
      modules.hardware.nvidia.enable = true;
      modules.services.enable = true;
      modules.services.qmk.enable = true;
      modules.services.virtualbox.enable = true;
      modules.services.tailscale.enable = true;
      modules.theme.enable = true;
      modules.gaming.all = true;
      modules.programs.enable = true;
      modules.desktop.enable = true;
      modules.desktop.compositor = "niri";
      modules.desktop.shell = "noctalia";

      # The Surface acts as an extra monitor via this sunshine server + moonlight.
      modules.services.sunshine.enable = true;

      # Deskflow: this machine serves the keyboard/mouse; desktop joins.
      modules.programs.deskflow.role = "server";

      programs.orchard.enable = true;
      programs.niXscout.enable = true;
      programs.nyaa-si.enable = true;
      programs.ytm-rs.enable = true;
      programs.neo-mangal.enable = true;
      programs.deviload.enable = true;
      networking.firewall.allowedTCPPorts = [ 24800 ];

      # Hybrid graphics (Intel iGPU + RTX 3050): PRIME offload.
      hardware.nvidia.prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };

      modules.artcraft.enable = true;
      modules.desktop.dotfiles.enable = true;

      #Required
      environment.systemPackages = [ pkgs.xwayland-satellite ];
      system.stateVersion = "26.05";
    };

  flake.nixosConfigurations.laptop = self.lib.mkHost {
    modules = [
      "host-laptop"

      ../../hosts/laptop/hardware-configuration.nix
    ]
    ++ self.lib.commonModules
    ++ [ "theme-stylix" ];
  };
}
