{ self, inputs, ... }: {
  flake.nixosModules.boot = { pkgs, config, lib, ... }: {

    boot.loader = {
      grub.enable = lib.mkForce false;
      systemd-boot = {
        enable = true;
        configurationLimit = 10; 
        consoleMode = "max";
      };

      efi = {
        canTouchEfiVariables = true;
        # Si tu partición EFI está en /boot, esto está bien. 
        # Si usas /boot/efi, cámbialo aquí.
        efiSysMountPoint = "/boot"; 
      };

      timeout = 5;
    };

    boot = {
      # --- CLAVE PARA NVIDIA Y PLYMOUTH ---
      initrd.systemd.enable = true; 
      
      plymouth = {
        enable = true;
        theme = lib.mkForce "huntShowdown-plymouth";
        themePackages = [ 
          (pkgs.stdenv.mkDerivation {
            pname = "huntShowdown-plymouth";
            version = "1.0";
            src = ./huntShowdown-plymouth; 
            installPhase = ''
              mkdir -p $out/share/plymouth/themes/huntShowdown-plymouth
              cp -r * $out/share/plymouth/themes/huntShowdown-plymouth/
            '';
          }) 
        ];
      };

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
        "nvidia-drm.modeset=1"
        # Evita que la terminal de texto se salte la cola frente a la animación
        "fbcon=nodefer" 
        "vt.global_cursor_default=0"
      ];

      initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
    };

    # Retraso para asegurar que vemos la animación
    systemd.services."delay-display-manager" = {
      wantedBy = [ "display-manager.service" ];
      before = [ "display-manager.service" ];
      script = "${pkgs.coreutils}/bin/sleep 3"; # Usamos la ruta absoluta al binario
    };
  };
}