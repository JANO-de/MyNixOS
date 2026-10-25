# Halo greeter (opt-in): greetd + a Quickshell login screen inside cage. Replaces SDDM when enabled.
# Test first with `quickshell -p ~/halo/greeter/greeter.qml` (preview only), then enable on the host.
# Rescue: pick the previous generation in the boot menu.
{ config, lib, pkgs, ... }:
let
  cfg = config.modules.desktop.haloGreeter;
  dir = ../../shell/halo/greeter;
in
{
  options.modules.desktop.haloGreeter = {
    enable = lib.mkEnableOption "the Halo greetd login screen (replaces SDDM)";
    scale = lib.mkOption {
      type = lib.types.str;
      default = "2";
      description = "UI scale of the greeter (cage has no HiDPI scaling; Surface panel = 2).";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "jano";
      description = "User shown on the login screen.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm.enable = lib.mkForce false;
    services.greetd = {
      enable = true;
      settings.default_session = {
        user = "greeter";
        command = lib.concatStringsSep " " [
          "${pkgs.dbus}/bin/dbus-run-session"
          "${lib.getExe pkgs.cage}" "-s" "--"
          "${pkgs.coreutils}/bin/env"
          "HOME=/tmp" "QT_QPA_PLATFORM=wayland" "QT_WAYLAND_DISABLE_WINDOWDECORATION=1" "QT_SCALE_FACTOR=${cfg.scale}"
          "HALO_GREETER_USER=${cfg.user}"
          "HALO_UWSM=${lib.getExe config.programs.uwsm.package}"
          "${lib.getExe pkgs.quickshell}" "-p" "${dir}/greeter.qml"
        ];
      };
    };
  };
}
