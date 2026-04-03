{ self, inputs, ... }: {
  flake.nixosModules.theme = { pkgs, ... }: {
    imports = [ 
      inputs.stylix.nixosModules.stylix 
      ../../assets
    ];

    stylix = {
      enable = true;
      # 1. Pon aquí la imagen final de la animación (el logo de GNOME que quieres de fondo)
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

      # Targets para que se aplique en todo el sistema
      targets.gnome.enable = true; 
      targets.gtk.enable = true;
      targets.plymouth.enable = true;
    };

    services.xserver.displayManager.gdm.settings = {
      "org/gnome/desktop/background" = {
        picture-uri = "file://${../../assets/background.png}";
      };
    };
  };
}