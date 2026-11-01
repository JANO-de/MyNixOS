# NVIDIA driver. Off until a host sets modules.hardware.nvidia.enable
# (the Surface only has Intel graphics).
{ config, lib, ... }:

let
  cfg = config.modules.hardware.nvidia;
in
{
  options.modules.hardware.nvidia.enable = lib.mkEnableOption "the NVIDIA driver";

  config = lib.mkIf cfg.enable {
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
