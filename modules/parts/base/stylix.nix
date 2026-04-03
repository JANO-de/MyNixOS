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
    };

    qt = {
      enable = true;
      platformTheme = lib.mkForce "gnome"; 
      style = lib.mkForce "adwaita-dark";
    };

    environment.sessionVariables = {
      XCURSOR_SIZE = "24";
      XCURSOR_THEME = "Bibata-Modern-Ice";
      QT_QPA_PLATFORMTHEME = "gnome";
    };
  };
}
