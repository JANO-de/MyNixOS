# Touch-first bits for the Surface Pro 5. Imported only by hosts/surface.
#
# The tablet is usable with or without the Type Cover, so it needs an
# on-screen keyboard. niri starts wvkbd docked at the bottom of the screen
# (see @TABLET_TOP@ in modules/home/niri/config.kdl) and Mod+N hides/shows it
# through `wvkbd-toggle`.
{ pkgs, ... }:

let
  # -H: height in portrait, -L: height in landscape. ~15% of the screen either
  # way, which is about right for a 2736x1824 panel at scale 2.
  wvkbdArgs = "-H 210 -L 160";
in
{
  environment.systemPackages = [
    pkgs.wvkbd
    pkgs.brightnessctl # Fn brightness keys, also handy for on-screen OSDs

    # `wvkbd-toggle`: starts the keyboard if it is not running, otherwise
    # SIGRTMIN (34) toggles its visibility. -x matches the exact process name
    # so we never signal anything else. niri starts wvkbd at session start
    # (see @TABLET_TOP@ in modules/home/niri/config.kdl), so this mostly acts
    # as the hide/show switch; starting it if dead is just belt and braces.
    (pkgs.writeShellScriptBin "wvkbd-toggle" ''
      if pgrep -x wvkbd >/dev/null; then
        pkill -34 -x wvkbd
      else
        setsid wvkbd ${wvkbdArgs} >/dev/null 2>&1 &
      fi
    '')
  ];
}
