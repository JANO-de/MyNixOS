{
  pkgs,
  lib,
  theme,
  tablet,
  ...
}:

let
  # Touch-only hosts (the Surface Pro 5) get the digitiser mapped to the
  # internal panel: niri maps an unmapped touchscreen to the union of all
  # outputs, which is wrong as soon as something is plugged into the USB-C
  # port. This goes inside the existing `input { }` node — niri allows only
  # one of those.
  tabletInput = lib.optionalString tablet ''
    // Surface Pro 5 digitiser (Wacom AES touch + pen, both absolute devices)
    touch {
        map-to-output "eDP-1"
    }

    tablet {
        map-to-output "eDP-1"
    }
  '';

  # On-screen keyboard and auto-rotation, tablet only.
  #
  # wvkbd starts hidden (`--hidden`) and `--auto` pops it up only when the
  # focused app requests a text input (input-method-v2, which niri
  # implements), then hides it when the text input goes away. So the OSK no
  # longer eats screen space until you actually have to type.
  #
  # iio-niri listens to iio-sensor-proxy's accelerometer and rotates eDP-1
  # after you, e.g., flip the tablet into portrait. It's firewall-safe: it
  # only calls `niri msg output ... transform` via IPC. If the SP5's
  # accelerometer doesn't surface in Linux, it simply idles and the manual
  # Mod+F9/F10/F12 binds from TABLET_BINDS cover rotation instead.
  tabletTop = lib.optionalString tablet ''
    // --- Surface Pro 5 (tablet) ---
    spawn-at-startup "wvkbd -H 210 -L 160 --hidden --auto"
    spawn-at-startup "iio-niri" "listen" "--monitor" "eDP-1"
    // --- /Surface Pro 5 ---
  '';

  # Indented so it lands inside `binds { }`. Mod+F9/F10 rotate eDP-1 one way
  # around (left/right), Mod+F12 resets; Mod+N hides/shows the OSK manually as
  # a fallback when the Type Cover is on and auto-show is in the way. Plain
  # strings on purpose: Nix strips the common indentation out of indented
  # strings, which would take the intended indent with it.
  tabletBinds = lib.optionalString tablet
    "\n"
    + "    Mod+F9 { spawn \"niri\" \"msg\" \"output\" \"eDP-1\" \"transform\" \"90\"; }\n"
    + "    Mod+F10 { spawn \"niri\" \"msg\" \"output\" \"eDP-1\" \"transform\" \"270\"; }\n"
    + "    Mod+F12 { spawn \"niri\" \"msg\" \"output\" \"eDP-1\" \"transform\" \"normal\"; }\n"
    + "    Mod+N { spawn \"wvkbd-toggle\"; }\n";

  # Inject theme colors and host-specific bits into the static KDL template
  content = lib.replaceStrings
    [
      "@FOCUS@"
      "@FOCUS_INACTIVE@"
      "@EDP_SCALE@"
      "@TABLET_INPUT@"
      "@TABLET_TOP@"
      "@TABLET_BINDS@"
    ]
    [
      (theme.color "accent")
      (theme.color "surface")
      # 2736x1824 at scale 1 is unusably small; 2 gives 1368x912.
      (if tablet then "2" else "1")
      tabletInput
      tabletTop
      tabletBinds
    ]
    (builtins.readFile ./niri/config.kdl);
in
{
  xdg.configFile."niri/config.kdl" = {
    source = pkgs.runCommand "niri-config-validated" {
      nativeBuildInputs = [ pkgs.niri ];
      passAsFile = [ "content" ];
      inherit content;
    } ''
      niri validate --config "$contentPath"
      cp "$contentPath" $out
    '';
  };
}
