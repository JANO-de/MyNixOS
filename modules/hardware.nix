# Hardware bits shared by the hosts: bluetooth, firmware, input, graphics,
# NVIDIA (switchable) and the external "Elements" drive (switchable).
{ config, lib, pkgs, ... }:

{
  options.hardware.nvidia.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Set up the NVIDIA driver. Turn off on hosts without an NVIDIA GPU (the Surface only has Intel graphics).";
  };

  config = lib.mkMerge [
    # ---- always on ----
    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings.General = {
          Experimental = true;
          ControllerMode = "dual";
        };
      };

      hardware.enableAllFirmware = true;
      hardware.enableRedistributableFirmware = true;
      hardware.firmware = [ pkgs.linux-firmware ];

      services.libinput.enable = true;
      hardware.graphics.enable = true;
    }

    # ---- NVIDIA (desktop, laptop) ----
    (lib.mkIf config.hardware.nvidia.enable {
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        # Pin the legacy 580.x driver: the GTX 1060 (Pascal) was dropped by the
        # current NVIDIA branch (595.xx and later ignore the GPU: no DRM render
        # node, so SDDM and the compositor session fail and login hangs). The
        # 580.xx legacy branch still supports Pascal.
        package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
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
    })
  ];
}
