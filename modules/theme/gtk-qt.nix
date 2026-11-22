# Home Manager base for user jano. GTK/Qt colours, fonts and cursor come from Stylix
# (modules/theme/stylix.nix); this file only keeps the account basics and the icon theme.
{ pkgs, ... }:

{
  home.username = "jano";
  home.homeDirectory = "/home/jano";
  home.stateVersion = "26.05";

  home.packages = [ pkgs.jq ];

  gtk = {
    enable = true;
    iconTheme = {
      name = "WhiteSur-dark";
      package = pkgs.whitesur-icon-theme;
    };
  };

  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;
}
