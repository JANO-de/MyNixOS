# awww — the Wayland wallpaper daemon.
#
# On niri hosts this module only has to make the binary available: the iNiR
# shell probes for `awww` and `awww-daemon` at startup, defaults
# `background.backend.provider` to "awww" and, when both are found, starts its
# own transient daemon and pushes the wallpaper per output. Without the package
# in the session PATH the shell silently falls back to its internal renderer,
# which is why installing it is all the desktop/laptop need.
#
# Hosts without the shell (the Surface runs a full desktop instead) have
# nothing to drive the daemon, so `image` additionally brings up a service for
# them. Only one awww daemon may own the layer-shell surfaces of a session,
# hence the shell hosts never get that service.
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop.awww;

  shellDrivesAwww = config.modules.desktop.niri.enable;
  wallpaperSet = cfg.image != null;
  manageService = !shellDrivesAwww && wallpaperSet;

  # GNOME paints its desktop background above the background layer, so an awww
  # surface stays hidden until GNOME's own picture is cleared. Skipped while no
  # wallpaper is configured, otherwise the session would end up bare.
  clearGnomeBackground = ''
    ${lib.getExe pkgs.gsettings} set org.gnome.desktop.background picture-uri ""
    ${lib.getExe pkgs.gsettings} set org.gnome.desktop.background picture-uri-dark ""
    ${lib.getExe pkgs.gsettings} set org.gnome.desktop.background picture-options "none"
  '';

  # The service can start before the compositor socket exists, so wait for the
  # daemon instead of assuming it. Runs as ExecStartPost so the unit does not
  # report "active" until the image was actually accepted.
  applyWallpaper = pkgs.writeShellApplication {
    name = "awww-apply-wallpaper";
    runtimeInputs = [ pkgs.coreutils pkgs.awww ];
    text = ''
      ${lib.optionalString config.modules.desktop.gnome.enable clearGnomeBackground}
      image=${lib.escapeShellArg cfg.image}
      for _ in $(seq 1 60); do
        if awww query >/dev/null 2>&1; then
          if awww img "$image"; then
            exit 0
          fi
        fi
        sleep 0.5
      done
      echo "awww-apply-wallpaper: no awww daemon answered within 30s" >&2
      exit 1
    '';
  };
in
{
  options.modules.desktop.awww = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install awww, the Wayland wallpaper daemon used as the wallpaper backend.";
    };

    image = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/home/jano/Pictures/wallpaper.gif";
      description = ''
        Wallpaper awww should show. While this is null awww is installed but no
        daemon is started and the current wallpaper is left alone; setting it
        also starts the awww service on hosts that run no iNiR shell (GNOME).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.awww ];

    systemd.user.services.awww = lib.mkIf manageService {
      description = "awww wallpaper daemon";
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe' pkgs.awww "awww-daemon"}";
        ExecStartPost = lib.getExe applyWallpaper;
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
