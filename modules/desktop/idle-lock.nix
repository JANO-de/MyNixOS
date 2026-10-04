# Idle and power-key behaviour for the tablet.
#
# Three separate mechanisms, because GNOME's own knobs do not cover all of it:
#
#   * Idle -> login screen is logind's IdleAction, not a GNOME setting. Asking
#     gnome-settings-daemon to lock is the wrong lever here anyway: on this
#     machine gsd-media-keys is dead (see modules/desktop/volume-keys.nix), and
#     gsd-power's idle timer is the fragile part of that stack. logind does it
#     independently of the session, so the greeter still appears if a session
#     daemon is unhealthy.
    #
    #   * Suspend-on-idle is gsd-power's sleep-inactive-*, which does work here
    #     (gsd-power is healthy; only the media-keys plugin crashes). GNOME's
    #     screen blanking (idle-delay) is kept separate from both, so the
    #     sequence is: blank, then lock, then suspend.
#
#   * Power key is modules/desktop/power-button.nix's business: short press
#     blanks the screen, long press asks before powering off.
    #
    # modules/desktop/idle-lock.nix deliberately does not touch
    # services.logind.settings.Login.HandlePowerKey: hosts/surface/hardware.nix
    # keeps it at "ignore" so the shell's menu owns that key, and a short press
    # with a thumb on a 700 g tablet must not be mistaken for a request to power
    # off.
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop.idleLock;
in
{
  config = lib.mkIf (cfg.enable && config.modules.desktop.gnome.enable) {
    # Lock on idle is logind's IdleAction. It lives in logind.conf's [Login]
    # section -- there is no [User] section in logind.conf, and passing one makes
    # systemd 260 log "Unknown section 'User'. Ignoring." and silently do
    # nothing. nixpkgs' services.logind.settings.Login is a freeform submodule
    # over exactly these keys, so no drop-in is needed.
    services.logind.settings.Login = {
      IdleAction = "lock";
      IdleActionSec = cfg.lockAfter;
    };

    programs.dconf.profiles.user.databases = [
      {
        settings = {
          # Blank the screen when idle. 0 means "never", which on a tablet leaves
          # the panel lit indefinitely.
          #
          # The GVariant types matter here: nixpkgs compiles each keyfile value
          # through dconf/gvdb, and a plain "600" is stored as a GVariant *string*.
          # org.gnome.desktop.session idle-delay is declared 'u' (uint32), so dconf
          # rejects the string and silently falls back to the schema default of
          # 300s. mkUint32 emits the type marker gvdb needs, so use it rather
          # than toString.
          "org/gnome/desktop/session".idle-delay = lib.gvariant.mkUint32 cfg.blankAfter;
          # Lock the moment the screen blanks rather than sitting unlocked.
          "org/gnome/desktop/screensaver".lock-delay = lib.gvariant.mkUint32 0;

          # These are 'i' (int32) in the power schema, and dconf refuses to
          # write a bare number without knowing which GVariant type it is.
          "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-timeout = lib.gvariant.mkInt32 cfg.suspendAfter;
          "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "suspend";
          "org/gnome/settings-daemon/plugins/power".sleep-inactive-battery-timeout = lib.gvariant.mkInt32 cfg.suspendAfter;
          "org/gnome/settings-daemon/plugins/power".sleep-inactive-battery-type = "suspend";
        };
      }
    ];
  };
}
