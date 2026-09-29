{ lib, ... }:

{
  options.modules.desktop.plasma = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the KDE Plasma 6 desktop and SDDM. Disable on low-RAM/small-disk machines (e.g. tablets) that run niri only.";
    };
  };

  options.modules.desktop.niri = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run the niri compositor, its iNiR shell and the niri-only touch bits (wvkbd OSK, iio-niri rotation). Off for tablets that use GNOME instead.";
    };
  };

  options.modules.desktop.gnome = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install the GNOME desktop (GDM + GNOME Wayland session). Touch-first: built-in on-screen keyboard, auto screen rotation via iio-sensor-proxy, HiDPI scaling out of the box.";
    };
  };
}