# =============================================================================
#  Home-Manager module for the Quickshell Dynamic Island shell.
#  Put this folder at modules/desktop/shell/dynisland/ and import ./default.nix
#  from your home-manager config. Then:
#    1. stop eww + its python notification server (they conflict)
#    2. rebuild, log out/in (or `systemctl --user start dynisland`)
# =============================================================================
{ pkgs, lib, ... }:
let
  # Tools the shell calls at runtime (service PATH is minimal, so list them)
  runtimeDeps = with pkgs; [
    cava matugen brightnessctl networkmanager curl niri coreutils bash
  ];
in {
  home.packages = with pkgs; [ quickshell material-symbols inter ] ++ runtimeDeps;

  # The QML tree lives in ~/.config/quickshell/dynisland (run with `qs -c dynisland`)
  xdg.configFile."quickshell/dynisland".source = ./.;

  fonts.fontconfig.enable = true;

  systemd.user.services.dynisland = {
    Unit = {
      Description = "Dynamic Island shell (Quickshell)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/qs -c dynisland";
      Restart = "on-failure";
      Environment = [ "PATH=${lib.makeBinPath runtimeDeps}:/run/current-system/sw/bin" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
