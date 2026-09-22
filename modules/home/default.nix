{ config, pkgs, inputs, ... }:

{
  home.username = "jano";
  home.homeDirectory = "/home/jano";
  home.stateVersion = "26.05";

  imports = [
    ./niri.nix
    ./alacritty.nix
    ./theme.nix
  ];

  # These are NOT extra iNiR packages for the inir.service unit — the unit's
  # fixed PATH is fine. They are needed on the user's *login/manager* PATH
  # because `scripts/inir` re-imports PATH from `systemctl --user
  # show-environment` when its child commands run (settings window via
  # execDetached, wallpaper sync, etc.). Without `qs` (quickshell) on that
  # PATH, right-click → Settings silently fails with "qs not found".
  home.packages = [
    pkgs.quickshell
    (pkgs.python3.withPackages (ps: with ps; [ pip materialyoucolor pillow evdev numpy ]))
    pkgs.jq
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
