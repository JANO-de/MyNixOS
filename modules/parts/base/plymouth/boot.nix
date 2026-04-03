{ self, inputs, ... }: {
  flake.nixosModules.boot = { pkgs, config, lib, ... }: {

    boot.loader = {
      grub.enable = lib.mkForce false;
      systemd-boot = {
        enable = true;
        configurationLimit = 10; 
        consoleMode = "1920x1080";
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

      kernelParams = [ 
        "quiet" 
        "splash" 
        "nvidia-drm.modeset=1" 
        "fbcon=nodefer" 
        "vt.global_cursor_default=0"
      ];

      consoleLogLevel = 0;
      initrd.verbose = false;

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