{ self, inputs, ... }: {
  flake.nixosModules.nvidia = { config, pkgs, ... }: {
    # 1. Habilitar drivers de video en Xserver (también afecta a Wayland)
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      # Modesetting es REQUERIDO para Wayland (Plasma 6)
      modesetting.enable = true;
      # Power management puede ayudar con el suspend/resume
      powerManagement.enable = false;
      
      # Usa el driver "open source" de NVIDIA (solo para tarjetas serie 20xx o más nuevas)
      # Si tu tarjeta es vieja (serie 10xx o anterior), ponlo en false.
      open = true;
      # Habilita el menú de configuración de NVIDIA
      nvidiaSettings = true;
    };
  };
}
