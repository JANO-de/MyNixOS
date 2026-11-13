# OpenRGB: RGB control for RAM, motherboard headers and fans.
# Off until a host sets modules.hardware.openrgb.enable.
# Usage: rgb on [hex] | rgb off | rgb toggle
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.hardware.openrgb;
in
{
  options.modules.hardware.openrgb = {
    enable = lib.mkEnableOption "OpenRGB server and the `rgb` on/off command";

    motherboard = lib.mkOption {
      type = lib.types.enum [ "amd" "intel" ];
      default = "amd";
      description = "Motherboard platform, used to load the right i2c driver for RAM and headers.";
    };

    defaultColor = lib.mkOption {
      type = lib.types.str;
      default = "8b5cf6";
      description = "Hex color used by `rgb on` when none is given.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.hardware.openrgb = {
      enable = true;
      motherboard = cfg.motherboard;
    };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "rgb" ''
        state="''${XDG_RUNTIME_DIR:-/tmp}/rgb-state"
        orgb() { ${pkgs.openrgb}/bin/openrgb --client localhost "$@"; }
        # Paint every device one color. Direct mode first (Corsair RAM has no
        # Static), then Static; devices that support neither are skipped.
        paint() {
          n=$(orgb --list-devices | ${pkgs.gnugrep}/bin/grep -c '^[0-9]*: ')
          for i in $(${pkgs.coreutils}/bin/seq 0 $((n - 1))); do
            out=$(orgb -d "$i" --mode direct --color "$1" 2>&1)
            if echo "$out" | ${pkgs.gnugrep}/bin/grep -q '^Error'; then
              out=$(orgb -d "$i" --mode static --color "$1" 2>&1)
              if echo "$out" | ${pkgs.gnugrep}/bin/grep -q '^Error'; then
                echo "device $i: no direct/static mode, skipped" >&2
              fi
            fi
          done
        }
        on()  { paint "''${1:-${cfg.defaultColor}}"; echo on > "$state"; }
        off() { paint 000000; echo off > "$state"; }
        case "''${1:-toggle}" in
          on)     on "''${2:-}" ;;
          off)    off ;;
          toggle) if [ "$(cat "$state" 2>/dev/null)" = on ]; then off; else on; fi ;;
          *)      echo "usage: rgb [on [hex]|off|toggle]"; exit 1 ;;
        esac
      '')
    ];
  };
}
