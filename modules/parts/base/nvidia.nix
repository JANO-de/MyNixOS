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
        open = false;

        # Habilita el menú de configuración de NVIDIA
        nvidiaSettings = true;

        # Selecciona el driver estable
        package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # 2. Configuración extra para Wayland/Plasma
    environment.sessionVariables = {
        # Fuerza a las apps de Qt a usar Wayland
        QT_QPA_PLATFORM = "wayland";
        # Ayuda con el parpadeo en algunas apps de Electron
        NIXOS_OZONE_WL = "1";
        # Necesario para que NVIDIA y Wayland se lleven bien
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
  };
}