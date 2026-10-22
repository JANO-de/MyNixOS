# Chronos Terminal (Quickshell) as the session shell: active when
# modules.desktop.shell = "chronos" (Surface).
# The service runs the QML copy from the chronos flake input (needs `nix flake update chronos` + rebuild).
# `chronos-shell dev` stops the service and runs the repo copy instead (no rebuild needed).
{ config, pkgs, lib, inputs, ... }:
let
  cfg = config.modules.desktop;
  niri = inputs.chronos.packages.${pkgs.stdenv.hostPlatform.system}.niri; # the fork, NOT stock niri
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
  config = lib.mkIf (cfg.shell == "chronos") {
    fonts.packages = [ pkgs.ibm-plex ];
    services.udev.packages = [ pkgs.brightnessctl ];
    users.users.jano.extraGroups = [ "video" ];

    home-manager.users.jano = {
      home.packages = [ pkgs.quickshell chronosShell ];

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
            "CHRONOS_MODE=${cfg.defaultMode}"
            "XDG_DATA_DIRS=/run/current-system/sw/share:/etc/profiles/per-user/jano/share:%h/.nix-profile/share"
            "PATH=${binPath}:/run/wrappers/bin:/etc/profiles/per-user/jano/bin:/run/current-system/sw/bin"
          ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
