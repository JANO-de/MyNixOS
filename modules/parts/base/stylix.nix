{ self, inputs, ... }: {
  flake.nixosModules.theme = { pkgs, config, lib, ... }: {
    imports = [ 
      inputs.stylix.nixosModules.stylix 
    ];

    stylix = {
      enable = true;
      # Asegúrate de que esta ruta sea correcta desde la ubicación de style.nix
      image = ../../assets/background.png; 
      
      polarity = "dark";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";

      # --- CONFIGURACIÓN DE ICONOS ---
      icons = {
        enable = true;
        package = pkgs.tela-circle-icon-theme; 
        dark = "Tela-circle-dracula";          
        light = "Tela-circle-dracula";         
      };

      # --- CURSOR ---
      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 24;
      };

      # --- FUENTES ---
      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font";
        };
        sansSerif = {
          package = pkgs.noto-fonts;
          name = "Noto Sans";
        };
      };

      # --- TARGETS DE SISTEMA ---
      targets.sddm.enable = true;      # Stylix pondrá el fondo en SDDM automáticamente
      targets.gtk.enable = true;       # Tema para ventanas en Niri/Plasma
      targets.plymouth.enable = true;  # Intenta aplicar colores al cargador (si el tema lo soporta)
      targets.console.enable = true;   # Colores en la TTY
    };

    # Forzar el esquema de GNOME/GTK a nivel de sistema para Niri
    # Esto ayuda a que las apps encuentren los iconos y el cursor sin Home Manager
    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      # Nota: Dependiendo del tema de SDDM, la opción para el fondo varía.
      # Si usas el tema por defecto o uno simple:
      settings = {
        Theme = {
          CursorTheme = "Bibata-Modern-Ice";
        };
      };
    };

    # Variable de entorno para asegurar que el cursor se vea en Wayland
    environment.sessionVariables = {
      XCURSOR_SIZE = "24";
      XCURSOR_THEME = "Bibata-Modern-Ice";
    };
  };
}