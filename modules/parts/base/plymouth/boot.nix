{ self, inputs, ... }: {
  flake.nixosModules.boot = { pkgs, config, lib, ... }: {

    boot.loader = {
      grub.enable = true;

      systemd-boot = {
        enable = true;
        # Limita el número de generaciones en el menú para que no sea un caos
        configurationLimit = 10; 
        # Resolución de la consola (opcional)
        consoleMode = "max";
      };

      efi = {
       canTouchEfiVariables = true;
        efiSysMountPoint = "/boot"; # Asegúrate de que coincida con tu /etc/fixos (o hardware-configuration.nix)
      };

      # 4. Timeout del menú (segundos que espera antes de arrancar)
      timeout = 5;
    };

    boot = {
      # 1. Activar Plymouth
      plymouth = {
        enable = true;
        theme = lib.mkForce "huntShowdown-plymouth";
        themePackages = [ 
          (pkgs.stdenv.mkDerivation {
            pname = "huntShowdown-plymouth";
            version = "1.0";
            src = ./huntShowdown-plymouth-0.0.2; # La carpeta donde lo descomprimiste
            installPhase = ''
              # Creamos la ruta completa que espera Plymouth
              mkdir -p $out/share/plymouth/themes/huntShowdown-plymouth
              
              # Copiamos TODO el contenido a esa carpeta específica
              cp -r * $out/share/plymouth/themes/huntShowdown-plymouth/
              
              # Si por alguna razón el archivo .plymouth está dentro de una subcarpeta, 
              # esto lo sacará a la raíz del tema (ajusta si es necesario)
              # mv $out/share/plymouth/themes/huntShowdown-plymouth/carpeta-extra/* $out/share/plymouth/themes/huntShowdown-plymouth/
            '';
          }) 
        ];
      };

      # 2. Parámetros para que no salga texto (Silent Boot)
      consoleLogLevel = 0;
      initrd.verbose = false;
      kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
        "nvidia-drm.modeset=1" # Crítico para evitar parpadeos en NVIDIA
      ];

      # 3. Cargar NVIDIA en el Initrd (Early KMS) 
      # Esto evita que se quede el guion parpadeando antes de la animación
      initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
    };

    # Evitar que el sistema arranque tan rápido que se salte la animación
    systemd.services."delay-display-manager" = {
      wantedBy = [ "display-manager.service" ];
      before = [ "display-manager.service" ];
      script = "sleep 3"; # Ajusta los segundos según dure el vídeo/animación
    };
  };
}