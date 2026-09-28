# Touch-first bits for the Surface Pro 5. Imported only by hosts/surface.
#
# The tablet is usable with or without the Type Cover, so it needs an
# on-screen keyboard. niri starts wvkbd hidden (`--hidden`) and lets
# `--auto` pop it up whenever a focused app requests text input
# (input-method-v2, which niri implements), hiding it again afterwards.
# Mod+N (see @TABLET_BINDS@ in modules/home/niri.nix) still does a manual
# hide/show through `wvkbd-toggle`.
#
# The screen can be used in any orientation: iio-sensor-proxy feeds the
# accelerometer to `iio-niri` (spawned by niri, see @TABLET_TOP@), which
# rotates eDP-1 to match, and Mod+F9/F10/F12 do it by hand when there's no
# sensor to trust.
{ pkgs, ... }:

let
  # -H: height in portrait, -L: height in landscape. ~15% of the screen either
  # way, which is about right for a 2736x1824 panel at scale 2. --hidden +
  # --auto: starts out of the way and only appears when a text field is
  # focused.
  wvkbdArgs = "-H 210 -L 160 --hidden --auto";
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
