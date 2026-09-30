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

  options.modules.desktop.powerButton = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Short press on the power key blanks the screen (press again to wake), long press asks before powering off, and the sleep key stops suspending by accident. GNOME sessions only; requires modules.desktop.gnome.";
    };

    longPressMs = lib.mkOption {
      type = lib.types.ints.positive;
      default = 800;
      description = "How long the power key must be held to count as a long press rather than a short one.";
    };
  };

  options.modules.desktop.volumeKeys = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Make the hardware volume buttons adjust the volume, routed through keyd and a GNOME keybinding rather than through gnome-settings-daemon. Needed where gsd-media-keys fails to start, which leaves the buttons inert. GNOME sessions only; requires modules.desktop.gnome.";
    };
  };

  options.modules.desktop.idleLock = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Blank, lock to the login screen and then suspend when the tablet is left alone. GNOME sessions only; requires modules.desktop.gnome. The power key is unaffected: modules.desktop.powerButton still owns it.";
    };

    blankAfter = lib.mkOption {
      type = lib.types.ints.positive;
      default = 600;
      description = "Seconds of idleness before the screen blanks.";
    };

    lockAfter = lib.mkOption {
      type = lib.types.str;
      default = "10min";
      description = "Idle time after which logind locks the session to the login screen. Applied by logind rather than GNOME so it still works when a session daemon is unhealthy.";
    };

    suspendAfter = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1800;
      description = "Seconds of idleness before the tablet suspends, on both mains power and battery. Should be larger than the lock delay so the greeter gets a chance to appear first.";
    };
  };

  options.modules.desktop.customKeybindings = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Label shown in the keyboard shortcuts settings panel.";
          };
          command = lib.mkOption {
            type = lib.types.str;
            description = "Command run when the binding fires.";
          };
          binding = lib.mkOption {
            type = lib.types.str;
            description = "Keycode the binding listens for, in gsettings syntax (e.g. \"F15\"). Must not be a key the shell already claims.";
          };
        };
      }
    );
    default = [ ];
    description = ''
      GNOME custom keybindings, as { name, command, binding } records.

      These are collected here and written as a single
      org/gnome/settings-daemon/plugins/media-keys custom-keybindings value by
      the GNOME module. A single owner matters: that gsettings key holds one
      list, so two modules writing it separately would silently overwrite each
      other and only the last one would take effect.
    '';
  };

  options.modules.desktop.greeterOsK = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Put an on-screen keyboard in the greeter, so a touch-only device can be logged into. Uses the Qt virtual keyboard, which SDDM loads as the greeter's input method and shows on top of the password field. SDDM greeters only (gdm has no equivalent knob).";
    };
  };
}