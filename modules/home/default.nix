{ config, pkgs, inputs, ... }:

{
  home.username = "jano";
  home.homeDirectory = "/home/jano";
  home.stateVersion = "26.05";

  imports = [
    ./niri.nix
    ./theme.nix
  ];

  # Shadow the system Steam desktop entry with one that forces UI scaling,
  # so -forcedesktopscaling is applied no matter how Steam is launched.
  xdg.desktopEntries.steam = {
    name = "Steam";
    genericName = "Steam";
    exec = "env STEAM_FORCE_DESKTOPUI_SCALING=1.5 steam -forcedesktopscaling 1.5 %U";
    icon = "steam";
    categories = [ "Game" ];
    mimeType = [ "x-scheme-handler/steam" "x-scheme-handler/steamlink" ];
    terminal = false;
  };
}
