{ self, inputs, ... }: 
{
  flake.nixosModules.gamingcore = { pkgs, ...}: 
  {
    hardware.opengl = {
      enable = true;
    };
  };
}