# NVIDIA driver (switchable).
{ config, lib, ... }:

{
  options.hardware.nvidia.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Set up the NVIDIA driver. Turn off on hosts without an NVIDIA GPU (the Surface only has Intel graphics).";
  };

  config = lib.mkIf config.hardware.nvidia.enable {
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.legacy_580;
      open = lib.mkDefault false;
      modesetting.enable = true;
      powerManagement.enable = true;
      nvidiaSettings = true;
    };
  };
}
