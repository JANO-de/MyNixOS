{ self, inputs, ... }: {
  flake.nixosModules.boot = { pkgs, config, lib, ... }: {

    boot.loader = {
      grub.enable = lib.mkForce false;
      systemd-boot = {
        enable = true;
        configurationLimit = 10; 
        consoleMode = "auto";
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
      initrd.systemd.enable = true; # CRÍTICO
      plymouth = {
        enable = true;
        theme = "huntShowdown-plymouth";
        themePackages = [
          (pkgs.stdenv.mkDerivation {
            pname = "huntShowdown-plymouth";
            version = "0.0.2";
            src = ./huntShowdown-plymouth-0.0.2;
            installPhase = ''
              mkdir -p $out/share/plymouth/themes/huntShowdown-plymouth
              cp -r * $out/share/plymouth/themes/huntShowdown-plymouth
            '';
          })
        ];
      };
      kernelParams = [ "quiet" "splash" "nvidia-drm.modeset=1" "fbcon=nodefer" ];
      loader.systemd-boot.enable = true;
    };

    # Retraso para asegurar que vemos la animación
    systemd.services."delay-display-manager" = {
      wantedBy = [ "display-manager.service" ];
      before = [ "display-manager.service" ];
      script = "${pkgs.coreutils}/bin/sleep 3"; # Usamos la ruta absoluta al binario
    };
  };
}