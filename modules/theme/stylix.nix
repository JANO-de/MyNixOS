# Stylix: system-wide theme from one base16 scheme (Gruvbox dark). Independent of the shell.
{ pkgs, theme, ... }:
{
  stylix = {
    enable = true;
    polarity = "dark";
    cursor = {
      package = pkgs.callPackage ./n-cursor.nix { };
      name = "N-Murder-Drones";
      size = 24;
    };
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    fonts = {
      sansSerif = {
        package = pkgs.inter;
        name = theme.fonts.sans;
      };
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = theme.fonts.terminal;
      };
    };
  };

  # niri-flake would generate its own config.kdl; yours is managed from dotfiles.
  home-manager.sharedModules = [ { stylix.targets.niri.enable = false; } ];
}
