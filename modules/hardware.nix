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
      # Common bits only. Per-host: driver branch, open modules, PRIME (see hosts/).
      (lib.mkIf config.hardware.nvidia.enable {
        services.xserver.videoDrivers = [ "nvidia" ];
        hardware.nvidia = {
          # Default: 580 legacy branch (last one with Pascal support; the GTX 1060
          # on the desktop needs it). Hosts with newer GPUs may override.
          package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.legacy_580;
          open = lib.mkDefault false; # Pascal has no open-module support
          modesetting.enable = true;
          powerManagement.enable = true;
          nvidiaSettings = true;
      };
    })
  ];
}
