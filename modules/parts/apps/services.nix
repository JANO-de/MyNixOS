{ self, inputs, ... }: {
  flake.nixosModules.services = { pkgs, lib, config, ... }: 
  {
    services = {
      dunst.enable = true;
      flatpak.enable = true;
    };
  };
}