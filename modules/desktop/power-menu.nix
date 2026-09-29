# The power key opens a small action menu instead of the shell's own
# end-session dialog.
#
# Why this is not just a GNOME keybinding: the tablet's power button is
# reported as XF86PowerButton, and gnome-settings-daemon always claims that key,
# so the shell's dialog wins and hibernate is not reachable at all. keyd
# therefore rewrites the key to F13 before the session ever sees it, and the
# keybinding below fires this menu. The sleep key is remapped to an unbound key
# for the same reason: a tablet carried in a bag should not suspend by accident.
#
# Actions the running system cannot perform are hidden rather than offered and
# then failing: hibernate only shows up when the kernel advertises disk sleep,
# which in turn needs a resume device to be configured.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.desktop.powerMenu;

  menu = pkgs.writeShellApplication {
    name = "power-menu";
    runtimeInputs = [
      pkgs.yad
      pkgs.gnome-session
      pkgs.systemd
      pkgs.util-linux
    ];
    text = ''
      can_hibernate=0
      if grep -qw disk /sys/power/state 2>/dev/null; then
        can_hibernate=1
      fi

      labels=()
      add() { labels+=("$1"); }
      add "Lock screen"
      add "Log out"
      add "Suspend"
      if [ "$can_hibernate" = 1 ]; then
        add "Hibernate"
      fi
      add "Restart"
      add "Shut down"
      add "Cancel"

      choice=$(
        yad --list \
          --title="Power" \
          --text="What should happen?" \
          --width=340 --height=-1 \
          --window-icon=system-shutdown \
          --column="Action":1 \
          --hide-column=1 \
          --print-column=1 \
          --button="OK":0 --button="Cancel":1 \
          "''${labels[@]}" || exit 0
      )

      case "$choice" in
        "Lock screen") loginctl lock-session ;;
        "Log out") gnome-session-quit --logout --no-prompt ;;
        "Suspend") systemctl suspend ;;
        "Hibernate") systemctl hibernate ;;
        "Restart") systemctl reboot ;;
        "Shut down") systemctl poweroff ;;
        *) exit 0 ;;
      esac
    '';
  };
in
{
  config = lib.mkIf (cfg.enable && config.modules.desktop.gnome.enable) {
    environment.systemPackages = [ menu ];

    # keyd 2.x: the mapping lives in a named keyboard section. `*` (the default
    # `ids`) covers the built-in buttons, and the rewrite happens in the
    # kernel-input layer, before GNOME's media-key handling.
    services.keyd = {
      enable = true;
      keyboards.tablet = {
        settings.main = {
          "KEY_POWER" = "KEY_F13";
          "KEY_SLEEP" = "KEY_F14";
        };
      };
    };

    # F13 is unbound in GNOME, so the custom binding is the only thing that
    # reacts to it.
    programs.dconf.profiles.user.databases = [
      {
        settings."org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
          ''
            [{
              "name": "Power menu",
              "command": "${lib.getExe menu}",
              "binding": "F13"
            }]
          ''
        ];
      }
    ];
  };
}
