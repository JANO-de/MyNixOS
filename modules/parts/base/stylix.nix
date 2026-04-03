{ self, inputs, ... }: {
  flake.nixosModules.theme = { pkgs, config, lib, ... }: {
    imports = [ 
      inputs.stylix.nixosModules.stylix 
    ];

    stylix = {
      enable = true;
      image = ../../assets/background.png; 
      
      polarity = "dark";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";

      icons = {
        enable = true;
        package = pkgs.tela-circle-icon-theme; 
        dark = "Tela-circle-dracula";          
        light = "Tela-circle-dracula";         
      };

      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 24;
      };

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

      targets.gtk.enable = true;       
      targets.plymouth.enable = true;  
    };

    qt = {
      enable = true;
      platformTheme = lib.mkForce "gnome"; 
      style = lib.mkForce "adwaita-dark";
    };

    services.displayManager.sddm = {
      enable = true;
      # --- CAMBIO AQUÍ ---
      # Ponlo en false. Esto hace que la pantalla de LOGIN sea X11 (estable con NVIDIA).
      # Niri seguirá abriéndose en Wayland sin problemas.
      wayland.enable = lib.mkForce false; 
      
      settings = {
        Theme = {
          CursorTheme = "Bibata-Modern-Ice";
        };
      };
    };

    environment.sessionVariables = {
      XCURSOR_SIZE = "24";
      XCURSOR_THEME = "Bibata-Modern-Ice";
      QT_QPA_PLATFORMTHEME = "gnome";
    };
  };
}