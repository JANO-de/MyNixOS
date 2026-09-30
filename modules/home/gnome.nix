# Touch-first GNOME tweaks for the Surface Pro 5. Imported only when
# `gnomeEnabled` is passed to home-manager (in hosts/surface/default.nix).
#
# GNOME's own defaults already cover the tablet basics — on-screen keyboard on
# touch focus, autorotation (via iio-sensor-proxy), swipe navigation — so these
# are adjustments, not a replacement.
{ pkgs, lib, ... }:

{
  dconf.settings = {
    # Favourites that make sense without a keyboard / with the Type Cover off.
    "org/gnome/shell".favorite-apps = [
      "org.gnome.Nautilus.desktop"
      "org.gnome.Software.desktop"
      "org.gnome.TextEditor.desktop"
      "org.gnome.Calculator.desktop"
      "com.github.xournalpp.xournalpp.desktop"
      "com.github.flxzt.rnote.desktop"
    ];

    # Show the on-screen keyboard toggle in the quick settings so it can be
    # forced when the screen keyboard is wanted even with the Type Cover on.
    "org/gnome/desktop/a11y/applications".screen-keyboard-enabled = true;

    # HiDPI panel: 2736x1824 at 1x is unusably small; leave the default scale
    # but make text a touch friendlier under heavy zoom.
    "org/gnome/desktop/interface".text-scaling-factor = 1.0;

    # GNOME asks before suspending when on battery; a tablet should just sleep.
    "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "suspend";
    "org/gnome/settings-daemon/plugins/power".sleep-inactive-battery-type = "suspend";
  };

  # GNOME Software (pw) UI dependency path convenience.
  # Home Manager's per-user packages complement the system ones.
  # xournalpp: PDF annotation (annotate.me.sh opens PDFs straight into it).
  # rnote: infinite-canvas handwriting with live PDF background.
  # Both take pen pressure, pen eraser-end and tool-type palm rejection from
  # iptsd; the pen itself is configured in gnome-control-center (Wacom panel).
  home.packages = [ pkgs.gnome-tweaks pkgs.xournalpp pkgs.rnote ];
}