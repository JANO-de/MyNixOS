# Touch-first bits for the Surface Pro 5. Imported only by hosts/surface.
#
# The tablet is usable with or without the Type Cover, so it needs an
# on-screen keyboard. wvkbd-mobintl runs as a systemd user service
# (systemd.user.services.wvkbd below), starts hidden, and pops up only while
# the focused window has a text input (`wvkbd --auto`). Over the niri
# overview there is no text focus, so the keyboard stays out of the way there
# too.
#
# --auto needs a wvkbd new enough to support it, hence the nixpkgs-unstable
# package below: nixpkgs 26.05 ships 0.19.4 whose binary rejects the flag. 0.20
# implements it over the input-method protocol (zwp_input_method_v2), which
# niri 26.04 exposes. Mod+N still hides/shows it manually (see @TABLET_BINDS@
# in modules/home/niri.nix) through `wvkbd-toggle`.
#
# The screen can be used in any orientation: iio-sensor-proxy feeds the
# accelerometer to `iio-niri` (spawned by niri, see @TABLET_TOP@), which
# rotates eDP-1 to match, and Mod+F9/F10/F12 do it by hand when there's no
# sensor to trust.
{ pkgs, pkgs-unstable, ... }:

let
  # wvkbd 0.20 from unstable. The binary nixpkgs ships is `wvkbd-mobintl`
  # (from the mobintl fork), not `wvkbd` — using the wrong name makes every
  # spawn fail silently. That took a while to find; do not "fix" the name
  # back.
  wvkbd = pkgs-unstable.wvkbd;

  # -H: height in portrait, -L: height in landscape. ~15% of the screen either
  # way, which is about right for a 2736x1824 panel at scale 2. --hidden:
  # start off-screen; --auto: show only while a text input is focused.
  wvkbdArgs = "-H 210 -L 160 --hidden --auto";
in
{
  environment.systemPackages = [
    wvkbd
    pkgs.iio-niri # auto-rotation daemon (spawned from the niri config)
    pkgs.brightnessctl # Fn brightness keys, also handy for on-screen OSDs

    # `wvkbd-toggle`: starts the keyboard if it is not running, otherwise
    # SIGRTMIN (34) toggles its visibility. -x matches the exact process name
    # so we never signal anything else. The systemd user service runs the
    # keyboard at session start; this mostly acts as the manual show/hide
    # switch, and starting it if the service somehow left it dead is belt and
    # braces.
    (pkgs.writeShellScriptBin "wvkbd-toggle" ''
      if pgrep -x wvkbd-mobintl >/dev/null; then
        pkill -34 -x wvkbd-mobintl
      else
        setsid wvkbd-mobintl ${wvkbdArgs} >/dev/null 2>&1 &
      fi
    '')
  ];

  # Start the keyboard as a user service instead of via niri's
  # spawn-at-startup: the latter races the Wayland socket at boot and the
  # keyboard routinely never came up. systemd orders it after the graphical
  # session and restarts it if it dies. WAYLAND_DISPLAY is set explicitly
  # because user services don't inherit it otherwise.
  systemd.user.services.wvkbd = {
    description = "On-screen virtual keyboard";
    after = [ "graphical-session-pre.target" ];
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${wvkbd}/bin/wvkbd-mobintl ${wvkbdArgs}";
      Restart = "on-failure";
      Environment = "WAYLAND_DISPLAY=wayland-1";
    };
  };

  # Accelerometer/gyro subscription for auto-rotation (and for future
  # orientation-aware apps). Harmless if the device exposes no sensor.
  hardware.sensor.iio.enable = true;
}
