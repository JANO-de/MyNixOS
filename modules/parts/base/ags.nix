{ inputs, ... }: {
  flake.nixosModules.ags = { pkgs, ... }: {
    # 1. Instalamos AGS y lo necesario para que tus widgets funcionen
    environment.systemPackages = [
      inputs.ags.packages.${pkgs.system}.default
      pkgs.gtk-layer-shell
      pkgs.libdbusmenu-gtk3
      pkgs.bun         # Para ejecutar JS/TS rápido
      pkgs.sassc       # Para los estilos CSS
      pkgs.brightnessctl # Para controlar brillo desde la barra
      pkgs.networkmanager # Para el widget de red
    ];

    # 2. Opcional: Si quieres que AGS arranque solo al iniciar sesión
    systemd.user.services.ags = {
      description = "Aylur's GTK Shell";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${inputs.ags.packages.${pkgs.system}.default}/bin/ags run --gtk 3 /home/jano/.config/ags/app.js";
        Restart = "on-failure";
      };
      environment = {
        GDK_BACKEND = "wayland";
      };
    };
  };
}