# Services: an always-on base plus switchable extras (sunshine, waydroid,
# powertop, smartd). Host-specific big services live in ./extras
# (xampp: laptop, matrix: desktop).
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
    # ---- always on ----
    {
      networking.networkmanager.enable = true;
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 80 443 ];
        allowedUDPPortRanges = [
          { from = 4000; to = 4007; }
          { from = 8000; to = 8010; }
        ];
      };
      networking.firewall.checkReversePath = false;

      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      services.printing.enable = true;
      services.openssh.enable = true;

      # QMK/Keychron keyboards (Via/Vial/Launcher access without root)
      hardware.keyboard.qmk = {
        enable = true;
        keychronSupport = true;
      };
      services.udev.packages = [ pkgs.qmk-udev-rules ];
      services.udev.extraRules = ''
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", TAG+="uaccess"
      '';

      # Flatpak, with Flathub registered at activation so Bazaar finds apps out
      # of the box. (The pinned flatpak module has no `remotes` option.)
      # `|| true` keeps an offline activation from failing the switch.
      services.flatpak.enable = true;
      system.activationScripts.flathub-remote = lib.stringAfter [ "users" ] ''
        ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
      '';
    }

    # ---- Sunshine: capture runs through wlgrab on Wayland ----
    (lib.mkIf cfg.sunshine.enable {
      services.sunshine = {
        enable = true;
        openFirewall = true;
      };
      # NVENC needs libcuda.so.1 / libnvidia-encode.so.1 from
      # /run/opengl-driver/lib. Harmless for the software (libx264) encoder.
      systemd.user.services.sunshine.environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
    })

    # ---- Waydroid: nftables variant ----
    # Start with `waydroid session start` in a Wayland session, then
    # `waydroid show-full-ui`.
    (lib.mkIf cfg.waydroid.enable {
      virtualisation.waydroid.enable = true;
      virtualisation.waydroid.package = pkgs.waydroid-nftables;
    })

    # ---- powertop: tuning applied once per boot, nothing written to disk ----
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

    # ---- smartd: journal + desktop notifications, no MTA ----
    (lib.mkIf cfg.smartd.enable {
      services.smartd = {
        enable = true;
        autodetect = true;
        notifications.systembus-notify.enable = true;
      };
    })
  ];
}
