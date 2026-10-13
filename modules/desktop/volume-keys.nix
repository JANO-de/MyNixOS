# Hardware volume buttons, handled without gnome-settings-daemon.
#
# Why this exists: on this tablet gsd-media-keys segfaults during startup
# (NULL deref in media_key_new_for_path, called from on_key_grabber_ready)
# and is then held down by systemd's start limit, so GNOME has no media-key
# handler at all and the volume buttons appear dead. The crash is upstream and
# is not caused by the buttons themselves -- it reproduces with the gpio-keys
# module unloaded, with the udev keyboard tags removed and with keyd stopped.
#
# So instead of waiting for gsd, this module routes the buttons around it:
# keyd rewrites volup/voldown to F15/F16 in the kernel-input layer, and GNOME
# runs custom keybindings on those. That path never touches gsd-media-keys.
#
# keyd's own key names are used, not evdev's (lower case, no KEY_ prefix);
# `KEY_VOLUMEUP` is rejected outright by `keyd check`, which is the difference
# between a working remap and a config that is silently ignored.
#
# The keys are clamped against the sink's own range rather than going through a
# muted/volume restore dance, so holding the button down stops at 100% and at 0
# without wrapping.
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop.volumeKeys;

  # GNOME runs this with no useful PATH, so wpctl is referenced by absolute
  # store path rather than by name. wpctl ships in wireplumber (not
  # wireplusher, which only has the C library) and is what PipeWire sessions
  # already use.
  wpctl = "${pkgs.wireplumber}/bin/wpctl";

  # The sign wpctl expects for a relative step: the percent comes first, then
  # "+" or "-" (0.05+). Passing "up"/"down" instead makes wpctl print its help
  # text and change nothing.
  step =
    sign:
    let
      direction = if sign == "+" then "up" else "down";
    in
    pkgs.writeShellApplication {
      name = "volume-key-${direction}";
      runtimeInputs = [ pkgs.wireplumber ];
      text = ''
        sink=@DEFAULT_AUDIO_SINK@
        current=$(${wpctl} get-volume "$sink" | grep -o '[0-9.]*' | tail -1)
        [ -n "$current" ] || current=0

        # A relative step is clamped to the sink's own range, so holding the
        # button stops at 100% and at 0 instead of wrapping. The fallback
        # restores the unchanged volume if wpctl rejects the argument, rather
        # than leaving the key with no effect and no visible error.
        ${wpctl} set-volume "$sink" "0.05${sign}" \
          || ${wpctl} set-volume "$sink" "$current"
      '';
    };
in
{
  config = lib.mkIf (cfg.enable && config.modules.desktop.gnome.enable) {
    services.keyd = {
      enable = true;
      keyboards.tablet.settings.main = {
        "volup" = "f15";
        "voldown" = "f16";
      };
    };

    # The binding list is written by the GNOME module, which owns that gsettings
    # key; this module only contributes its two entries.
    modules.desktop.customKeybindings = [
      {
        name = "Volume up";
        command = "${step "+"}";
        binding = "F15";
      }
      {
        name = "Volume down";
        command = "${step "-"}";
        binding = "F16";
      }
    ];
  };
}
