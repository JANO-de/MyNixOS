{ self, inputs, ... }: 
{
  flake.nixosModules.gamingcore = { pkgs, ...}: 
  {
    hardware.opengl = {
      enable = true;
    };

    services.xserver.videoDrivers = ["nvidia"];
    hardware.nvidia.modesetting.enable = true;
  };
}