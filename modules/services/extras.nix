# Switchable extras: sunshine, waydroid, powertop, smartd, QMK.
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.services;
in
{
  options.modules.services = {
    sunshine.enable = lib.mkEnableOption "Sunshine, the GPU screen-streaming server (pair it with moonlight, e.g. the Surface used as an extra monitor; first pairing at http://<host>:47990)";
    waydroid.enable = lib.mkEnableOption "Waydroid, Android in a container on top of the Wayland session";
    powertop.enable = lib.mkEnableOption "powertop --auto-tune once per boot (leaves Wi-Fi power saving alone, see hosts/halos1)";
    smartd.enable = lib.mkEnableOption "smartd, background SMART polling with journal and desktop notifications";
  };

  config = lib.mkMerge [
    # QMK/Keychron keyboards (Via/Vial/Launcher access without root)
    {
      hardware.keyboard.qmk = {
        enable = true;
        keychronSupport = true;
      };
      services.udev.packages = [ pkgs.qmk-udev-rules ];
      services.udev.extraRules = ''
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", TAG+="uaccess"
      '';
    }

    (lib.mkIf cfg.sunshine.enable {
      services.sunshine = {
        enable = true;
        openFirewall = true;
      };
      systemd.user.services.sunshine.environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
    })

    (lib.mkIf cfg.waydroid.enable {
      virtualisation.waydroid.enable = true;
      virtualisation.waydroid.package = pkgs.waydroid-nftables;
    })

    (lib.mkIf cfg.powertop.enable {
      systemd.services.powertop-auto-tune = {
        description = "Apply powertop's automatic power tuning";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-power-save.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${lib.getExe pkgs.powertop} --auto-tune";
        };
      };
    })

    (lib.mkIf cfg.smartd.enable {
      services.smartd = {
        enable = true;
        autodetect = true;
        notifications.systembus-notify.enable = true;
      };
    })
  ];
}
