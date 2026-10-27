# Hyprland touch helpers (surface-rotate, on-screen keyboard height). Imported by modules/desktop.
{ config, lib, pkgs, inputs, ... }:

# Step 2: touch plumbing for the Surface (hyprgrass, rotation, on-screen keyboard).
# Gate: only active when the Hyprland session is selected (adjust the option path).
let
  hyprgrass = inputs.hyprgrass.packages.${pkgs.stdenv.hostPlatform.system}.default;
  hyprPkg = config.programs.hyprland.package;

  # Virtual touchscreen from iptsd (name from `hyprctl devices`).
  touchDev = "iptsd-virtual-touchscreen-045e:001f";

  # surface-rotate [auto|0|1|2|3]
  # Sets monitor transform AND touch transform together via `hyprctl eval` (Lua API).
  surfaceRotate = pkgs.writeShellApplication {
    name = "surface-rotate";
    runtimeInputs = [ hyprPkg pkgs.jq pkgs.iio-sensor-proxy pkgs.coreutils pkgs.findutils ];
    text = ''
      if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        sig=$(find "/run/user/$(id -u)/hypr" -mindepth 1 -maxdepth 1 -type d ! -name chronos-shell -printf '%f\n' | head -1)
        export HYPRLAND_INSTANCE_SIGNATURE="$sig"
      fi

      apply() {
        local t=$1 line name scale
        line=$(hyprctl -j monitors | jq -r '[.[] | select(.name | startswith("eDP"))][0] | "\(.name) \(.scale)"')
        read -r name scale <<< "$line"
        hyprctl eval "hl.monitor({ output = '$name', mode = 'preferred', position = '0x0', scale = $scale, transform = $t })"
        hyprctl eval "hl.device({ name = '${touchDev}', transform = $t })"
      }

      case "''${1:-auto}" in
        0|1|2|3) apply "$1" ;;
        auto)
          monitor-sensor --accel | while read -r line; do
            case "$line" in
              *"orientation: normal"*|*"changed: normal"*) apply 0 ;;
              *left-up*)   apply 1 ;;
              *bottom-up*) apply 2 ;;
              *right-up*)  apply 3 ;;
              *) ;;
            esac
          done
          ;;
        *) echo "usage: surface-rotate [auto|0|1|2|3]" >&2; exit 2 ;;
      esac
    '';
  };

  # wvkbd heights in px (portrait / landscape). Keep in sync with shell/halo/services/Kbd.qml.
  kbdH = "420";
  kbdL = "300";

  osk = "sm.puri.OSK0";
  oskPath = "/sm/puri/OSK0";

  # kbd-toggle [toggle|show|hide]: with squeekboard running (tablet mode) it calls SetVisible over
  # D-Bus; otherwise it falls back to wvkbd (SIGRTMIN). State goes to $XDG_RUNTIME_DIR/kbd-visible.
  kbdToggle = pkgs.writeShellApplication {
    name = "kbd-toggle";
    runtimeInputs = [ pkgs.wvkbd pkgs.procps pkgs.coreutils pkgs.systemd pkgs.gawk ];
    text = ''
      state="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/kbd-visible"
      want="''${1:-toggle}"
      if systemctl --user is-active --quiet halo-osk; then
        cur=$(busctl --user get-property ${osk} ${oskPath} ${osk} Visible 2>/dev/null | awk '{print $2}' || true)
        if [ "$want" = toggle ]; then
          if [ "$cur" = true ]; then want=hide; else want=show; fi
        fi
        if [ "$want" = show ]; then v=true; else v=false; fi
        busctl --user call ${osk} ${oskPath} ${osk} SetVisible b "$v"
        exit 0
      fi
      if ! pgrep -x wvkbd-mobintl > /dev/null; then
        wvkbd-mobintl --hidden -H ${kbdH} -L ${kbdL} &
        sleep 0.3
        echo hidden > "$state"
      fi
      cur=$(cat "$state" 2>/dev/null || echo hidden)
      if [ "$want" = toggle ]; then
        if [ "$cur" = visible ]; then want=hide; else want=show; fi
      fi
      if [ "$want" = show ] && [ "$cur" != visible ]; then
        pkill -RTMIN -x wvkbd-mobintl
        echo visible > "$state"
      elif [ "$want" = hide ] && [ "$cur" = visible ]; then
        pkill -RTMIN -x wvkbd-mobintl
        echo hidden > "$state"
      fi
    '';
  };

  # kbd-watch: mirrors squeekboard's Visible property into kbd-visible, and its real height
  # (from the layer surface) into kbd-height, so the Halo shell can place the handle.
  kbdWatch = pkgs.writeShellApplication {
    name = "kbd-watch";
    runtimeInputs = [ pkgs.systemd pkgs.gawk pkgs.coreutils pkgs.jq hyprPkg ];
    text = ''
      rt="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      last=""
      while sleep 0.4; do
        v=$(busctl --user get-property ${osk} ${oskPath} ${osk} Visible 2>/dev/null | awk '{print $2}' || true)
        [ -n "$v" ] || continue
        if [ "$v" = true ]; then st=visible; else st=hidden; fi
        [ "$st" != "$last" ] || continue
        last="$st"
        if [ "$st" = visible ]; then
          sleep 0.5
          h=$(hyprctl layers -j 2>/dev/null | jq '[.. | objects | select(.namespace? == "osk") | .h] | max // empty' || true)
          [ -z "$h" ] || echo "$h" > "$rt/kbd-height"
        fi
        echo "$st" > "$rt/kbd-visible"
      done
    '';
  };
in
{
  config = lib.mkIf (config.modules.desktop.session == "hyprland") {
    environment.systemPackages = [ surfaceRotate kbdToggle kbdWatch pkgs.squeekboard pkgs.iio-sensor-proxy pkgs.evtest ];

    # Auto-rotation daemon. Test manually first: systemctl --user start surface-rotate
    systemd.user.services.surface-rotate = {
      description = "Rotate Hyprland monitor and touch from the accelerometer";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = lib.getExe surfaceRotate;
        Restart = "on-failure";
        RestartSec = 3;
      };
    };

    # Auto-showing on-screen keyboard (shows when a text field is focused, text-input-v3).
    # Started/stopped by set_mode() in hyprland-mode.lua: only in tablet mode.
    systemd.user.services.halo-osk = {
      description = "Squeekboard on-screen keyboard";
      serviceConfig = {
        ExecStart = lib.getExe pkgs.squeekboard;
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
    systemd.user.services.halo-osk-watch = {
      description = "Mirror squeekboard visibility/height for the Halo shell";
      partOf = [ "halo-osk.service" ];
      after = [ "halo-osk.service" ];
      serviceConfig = {
        ExecStart = lib.getExe kbdWatch;
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    # Included from hyprland.lua with: dofile("/etc/hypr/hyprland-touch.lua")
    environment.etc."hypr/hyprland-touch.lua".text = ''
      -- generated by modules/desktop/hyprland-touch.nix

      -- Load hyprgrass at startup; Hyprland reloads the config after the plugin loads,
      -- and the guarded block below then takes effect.
      hl.on("hyprland.start", function()
        hl.exec_cmd("hyprctl plugin load ${hyprgrass}/lib/libhyprgrass.so")
      end)

      hl.config({
        gestures = {
          workspace_swipe_touch = true,
          workspace_swipe_cancel_ratio = 0.15,
        },
      })

      if hl.plugin and hl.plugin.hyprgrass then
        hl.config({
          plugin = {
            hyprgrass = {
              sensitivity = 4.0,
              long_press_delay = 400,
              resize_on_border_long_press = true,
              edge_margin = 20,
            },
          },
        })

        -- 3-finger horizontal swipe: switch workspace
        hl.plugin.hyprgrass.gesture {
          pattern = { kind = "swipe", fingers = 3, direction = "horizontal" },
          action = "workspace",
        }

        -- Edge gestures are handled by Halo itself (TopEdge.qml / BottomEdge.qml) so they follow the
        -- finger in real time: top = shade, bottom = home (short) / app overview (long).
        -- Keyboard: SUPER+K or the Keyboard tile.

        -- 3-finger long-press: drag window
        hl.plugin.hyprgrass.bind {
          pattern = { kind = "longpress", fingers = 3 },
          action = hl.dsp.window.drag(),
          mouse = true,
        }
      end
    '';
    environment.etc."hypr/hyprland-mode.lua".source = ./hyprland-mode.lua;
    environment.etc."hypr/default-mode".text = config.modules.desktop.hyprlandMode + "\n";
  };
}
