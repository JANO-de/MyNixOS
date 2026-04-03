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
        themePackages = [ pkgs.adi1090x-plymouth-themes ];
        theme = lib.mkForce "target_2" ; # lib.mkForce "huntShowdown-plymouth";
      };
      kernelParams = [ "quiet" "splash" "nvidia-drm.fbdev=1" "nvidia-drm.modeset=1" "fbcon=nodefer" ];
    };

    # Retraso para asegurar que vemos la animación
    systemd.services."delay-display-manager" = {
      wantedBy = [ "display-manager.service" ];
      before = [ "display-manager.service" ];
      script = "${pkgs.coreutils}/bin/sleep 3"; # Usamos la ruta absoluta al binario
    };
  };
}