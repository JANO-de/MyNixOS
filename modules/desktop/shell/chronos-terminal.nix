# Chronos Terminal (Quickshell) as the session shell. Off by default:
#   modules.desktop.chronosTerminal.enable = true;
# Replaces dynisland's autostart (dynisland stays installed, just not started).
# The service runs the QML copy from the chronos flake input (needs `nix flake update chronos` + rebuild).
# `chronos-shell dev` stops the service and runs the repo copy instead (no rebuild needed).
{ config, pkgs, lib, inputs, ... }:
let
  cfg = config.modules.desktop.chronosTerminal;
  niri = inputs.chronos.packages.${pkgs.system}.niri; # the fork, NOT stock niri
  shellStore = "${inputs.chronos}/shell";
  shellRepo = "$HOME/Proyectos/chronos/shell";
  binPath = lib.makeBinPath [ niri pkgs.coreutils ];

  chronosShell = pkgs.writeShellScriptBin "chronos-shell" ''
    qs=${pkgs.quickshell}/bin/qs
    export PATH=${binPath}:$PATH
    case "$1" in
      dev)     systemctl --user stop chronos-terminal; $qs kill -p "${shellRepo}" 2>/dev/null; exec $qs -p "${shellRepo}" ;;
      stop)    systemctl --user stop chronos-terminal ;;
      start)   systemctl --user restart chronos-terminal ;;
      ipc)     shift; $qs -p "${shellRepo}" ipc call "$@" 2>/dev/null || $qs -p "${shellStore}" ipc call "$@" ;;
      log)     journalctl --user -u chronos-terminal -n 50 --no-pager ;;
      *)       echo "usage: chronos-shell {start|stop|dev|ipc <target> <fn> [args]|log}" ;;
    esac
  '';
in
{
  options.modules.desktop.chronosTerminal.enable =
    lib.mkEnableOption "Chronos Terminal shell (replaces dynisland autostart)";

  config = lib.mkIf cfg.enable {
    fonts.packages = [ pkgs.ibm-plex pkgs.departure-mono ];
    services.udev.packages = [ pkgs.brightnessctl ];
    users.users.jano.extraGroups = [ "video" ];

    home-manager.users.jano = {
      home.packages = [ pkgs.quickshell chronosShell pkgs.brightnessctl pkgs.wtype ];
      
      # only one shell autostarts
      systemd.user.services.dynisland.Install.WantedBy = lib.mkForce [ ];

      systemd.user.services.chronos-terminal = {
        Unit = {
          Description = "Chronos Terminal shell (Quickshell)";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.quickshell}/bin/qs -p ${shellStore}";
          Restart = "on-failure";
          Environment = [
            "XDG_DATA_DIRS=/run/current-system/sw/share:/etc/profiles/per-user/jano/share:%h/.nix-profile/share"
            "PATH=${binPath}:/run/wrappers/bin:/etc/profiles/per-user/jano/bin:/run/current-system/sw/bin"
          ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
