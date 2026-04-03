{ self, inputs, ... }: {
  flake.nixosModules.boot = { pkgs, config, lib, ... }: {
    imports = [
      self.nixosModules.ply
    ];
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
        "video=efifb:off" # Evita que el framebuffer básico choque con NVIDIA
      ];

      initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
    };

    systemd.settings.Manager = {
      RebootWatchdogSec = "10s";
      RuntimeWatchdogSec = "10s";
    };
  };
}