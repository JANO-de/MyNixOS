# GTK / Qt theming for user jano. Colors come from Noctalia templates (gtk3, gtk4, qt);
# this module only installs the base theme, icons, cursor and font.
{ pkgs, theme, ... }:

let
  gtkPkg = pkgs.whitesur-gtk-theme.override {
    colorVariants = [ "light" "dark" ];
    themeVariants = [ "default" ];
    opacityVariants = [ "solid" ];
    altVariants = [ "normal" ];
  };
in
{
  home.username = "jano";
  home.homeDirectory = "/home/jano";
  home.stateVersion = "26.05";

  home.packages = [
    pkgs.jq
    (pkgs.catppuccin-kvantum.override {
      variant = "mocha";
      accent = "mauve";
    })
  ];

  xdg.configFile."Kvantum/kvantum.kvconfig".text = "[General]\ntheme=catppuccin-mocha-mauve\n";

  gtk = {
    enable = true;
    theme = {
      name = "WhiteSur-Dark-solid";
      package = gtkPkg;
    };
    iconTheme = {
      name = "WhiteSur-dark";
      package = pkgs.whitesur-icon-theme;
    };
    font = {
      name = theme.fonts.sans;
      package = pkgs.inter;
    };
  };

  home.pointerCursor = {
    package = pkgs.apple-cursor;
    name = "macOS";
    size = 24;
    gtk.enable = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;
}
