{
  config,
  pkgs,
  lib,
  theme,
  ...
}:

let
  c = theme.palette;

  # Catppuccin GTK theme from nixpkgs
  gtkPkg = pkgs.catppuccin-gtk.override {
    variant = "mocha";
    accents = [ "mauve" ];
    size = "standard";
    tweaks = [ "black" ];
  };

  # Kvantum theme (Qt apps) from nixpkgs
  kvantumPkg = pkgs.catppuccin-kvantum.override {
    variant = "mocha";
    accent = "mauve";
  };

  # colors.css for GTK — same variables home-manager writes, so the theme
  # (catppuccin-gtk) and gtk.css agree with each other.
  colorsCss = lib.concatStringsSep "\n" (lib.mapAttrsToList
    (name: value: "@define-color ${name} ${value};")
    {
      bg = c.base;
      bg_alt = c.mantle;
      surface = c.surface0;
      surface_alt = c.surface1;
      fg = c.text;
      fg_muted = c.subtext1;
      fg_subtle = c.overlay1;
      accent = c.mauve;
      accent_alt = c.lavender;
      error = c.red;
      success = c.green;
      warning = c.yellow;
    });
in
{
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-mauve-standard+black";
      package = gtkPkg;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    font = {
      name = theme.fonts.sans;
      package = pkgs.inter;
    };
  };

  qt = {
    enable = true;
    platformTheme = "gtk3";
    kvantum = {
      enable = true;
      settings.General.theme = "catppuccin-mocha-mauve";
      themes = [ kvantumPkg ];
    };
  };

  # Keep the manual gtk.css/colors.css declarative and in sync with the theme
  xdg.configFile."gtk-3.0/colors.css".text = colorsCss;
  xdg.configFile."gtk-3.0/gtk.css".text = "@import 'colors.css';\n";
}
