# Touch-first bits for the Surface Pro 5. Imported only by hosts/surface.
#
# The tablet is usable with or without the Type Cover, so it needs an
# on-screen keyboard. niri starts wvkbd docked at the bottom of the screen
# (see @TABLET_TOP@ in modules/home/niri/config.kdl) so it is *always*
# visible and usable, and Mod+N hides/shows it (see @TABLET_BINDS@ in
# modules/home/niri.nix) through `wvkbd-toggle`.
#
# (Tried wvkbd --hidden --auto — pop-up only on text focus via
# input-method-v2 — but it didn't fire reliably in this niri build, so a
# keyboard that's simply there when you need it wins.)
#
# The screen can be used in any orientation: iio-sensor-proxy feeds the
# accelerometer to `iio-niri` (spawned by niri, see @TABLET_TOP@), which
# rotates eDP-1 to match, and Mod+F9/F10/F12 do it by hand when there's no
# sensor to trust.
{ pkgs, ... }:

let
  # -H: height in portrait, -L: height in landscape. ~15% of the screen either
  # way, which is about right for a 2736x1824 panel at scale 2. Starts docked
  # and visible.
  wvkbdArgs = "-H 210 -L 160";
in
{
  environment.systemPackages = [
    pkgs.wvkbd
    pkgs.iio-niri # auto-rotation daemon (spawned from the niri config)
    pkgs.brightnessctl # Fn brightness keys, also handy for on-screen OSDs

    # `wvkbd-toggle`: starts the keyboard if it is not running, otherwise
    # SIGRTMIN (34) toggles its visibility. -x matches the exact process name
    # so we never signal anything else. niri starts wvkbd at session start
    # (see @TABLET_TOP@ in modules/home/niri/config.kdl) with --auto, so this
    # mostly acts as the manual show/hide switch; starting it if dead is just
    # belt and braces.
    (pkgs.writeShellScriptBin "wvkbd-toggle" ''
      if pgrep -x wvkbd >/dev/null; then
        pkill -34 -x wvkbd
      else
        setsid wvkbd ${wvkbdArgs} >/dev/null 2>&1 &
      fi
    '')
  ];

  # Accelerometer/gyro subscription for auto-rotation (and for future
  # orientation-aware apps). Harmless if the device exposes no sensor.
  hardware.sensor.iio.enable = true;
}
