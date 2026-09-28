{ config, pkgs, lib, ... }:

{
  # Guarded by hardware.nvidia.enable (see options.nix) so hosts without an
  # NVIDIA GPU — the Surface Pro 5 only has Intel graphics — skip this.
  config = lib.mkIf config.hardware.nvidia.enable {
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
      nvidiaSettings = true;
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };
}
