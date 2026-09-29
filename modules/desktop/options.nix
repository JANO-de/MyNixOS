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

  options.modules.desktop.displayManager = lib.mkOption {
    type = lib.types.enum [ "gdm" "sddm" ];
    default = "gdm";
    description = "Which login screen greets the user. 'gdm' is the GNOME greeter; 'sddm' is the themable one (catppuccin here) and the only choice that can be themed on a GNOME session. Plasma hosts use SDDM regardless. Only one greeter is ever enabled.";
  };

  options.modules.desktop.powerMenu = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Make the power key open a menu (lock, log out, suspend, hibernate, restart, shut down) instead of the shell's end-session dialog, and stop the sleep key from suspending by accident. GNOME sessions only; requires modules.desktop.gnome.";
    };
  };
}