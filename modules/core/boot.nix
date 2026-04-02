{ self, inputs, ... }: 
{
  flake.nixosModules.bootcore = { pkgs, ...}: {
    boot = {
        # 1. Hacer el arranque "silencioso" para que no salgan letras sobre la animación
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
      ];

      # 2. Habilitar Plymouth
      plymouth = { 
        enable = true;
        # Elige un tema. 'breeze' es el de KDE, pero hay muchos.
        theme = "huntShowdown-plymouth"; 
      };
    };
    systemd.services."delay-display-manager" = {
      wantedBy = [ "display-manager.service" ];
      before = [ "display-manager.service" ];
      script = "sleep 3"; # Ajusta los segundos que dura tu animación
    };

    programs.dconf.enable = true;
  
    # Opción A: Usar un tema de GDM que permita cambiar el fondo
    services.xserver.displayManager.gdm.banner = "Bienvenido Jano"; # Opcional
  
    # Opción B (La mejor): Usar stylix (si lo tienes) o un override de carpeta
    # Para cambiar el fondo de GDM "a mano" en NixOS:
    services.xserver.displayManager.gdm.settings = {
      "org/gnome/desktop/background" = {
        picture-uri = "../parts/base/plymouth/hunt/media/ezgif-frame-173.png";
      };
    };
  };
}