{ config, lib, pkgs, ... }:
let
  cfg = config.modules.desktop;
  shellDir = ../../../shell/halo;

  # hyprctl needs the instance signature; fall back to scanning if the session did not export it.
  launcher = pkgs.writeShellScript "halo-launch" ''
    if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
      HYPRLAND_INSTANCE_SIGNATURE=$(${pkgs.findutils}/bin/find "$XDG_RUNTIME_DIR/hypr" -mindepth 1 -maxdepth 1 -type d ! -name chronos-shell -printf '%f\n' | ${pkgs.coreutils}/bin/head -1)
      export HYPRLAND_INSTANCE_SIGNATURE
    fi
    exec ${lib.getExe pkgs.quickshell} -p ${shellDir}
  '';

  # halo-ctl call home toggle|open|close  (talks to the running shell by its config path)
  haloCtl = pkgs.writeShellScriptBin "halo-ctl" ''
    exec ${lib.getExe pkgs.quickshell} -p ${shellDir} ipc "$@"
  '';
in
{
  config = lib.mkIf (cfg.shell == "halo") {
    environment.systemPackages = [
      haloCtl
      pkgs.brightnessctl # shade brightness slider
      pkgs.wireplumber # wpctl (volume)
      pkgs.networkmanager # nmcli (Wi-Fi tile)
      pkgs.bluez # bluetoothctl (Bluetooth tile)
    ];
    services.udev.packages = [ pkgs.brightnessctl ]; # backlight writable without root

    systemd.user.services.halo = {
      description = "Halo shell (Quickshell)";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      # hyprctl, surface-rotate and kbd-toggle must be reachable from the shell
      path = [ config.programs.hyprland.package "/run/current-system/sw" ];
      serviceConfig = {
        ExecStart = launcher;
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
