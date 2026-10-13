{ config, pkgs, lib, ... }:

{
  # Guarded by hardware.nvidia.enable (see options.nix) so hosts without an
  # NVIDIA GPU — the Surface Pro 5 only has Intel graphics — skip this.
  config = lib.mkIf config.hardware.nvidia.enable {
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      # Pin the legacy 580.x driver: this desktop's GTX 1060 (Pascal) was
      # dropped by the current NVIDIA branch — 595.xx and later "ignore" the
      # GPU ("NVRM: supported through the NVIDIA 580.xx Legacy drivers"), so
      # no DRM render node exists, the SDDM Wayland greeter and the niri
      # session both fail at startup and login hangs. The 580.xx legacy
      # branch still supports Pascal.
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
  };
}
