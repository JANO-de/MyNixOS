{ self, inputs, ... }: 
{
  flake.nixosModules.gamingcore = { pkgs, ...}: 
  {
    hardware.opengl = {
      enable = true;
    };

    services.xserver.videoDrivers = ["nvidia"];
    hardware.nvidia.modesetting.enable = true;

    hardware.nvidia.prime = {
      sync.enable = true;

      intelBusId = "PCI:0:0:2";

      nvidiaBusId = "PCI:0:1:0";
    };
  };
}