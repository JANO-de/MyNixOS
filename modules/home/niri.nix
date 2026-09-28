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

  # On-screen keyboard, docked at the bottom. niri has no touchscreen gestures
  # yet, so this is started with the session and toggled with a hotkey.
  tabletTop = lib.optionalString tablet ''
    // --- Surface Pro 5 (tablet) ---
    spawn-at-startup "wvkbd -H 210 -L 160"
    // --- /Surface Pro 5 ---
  '';

  # Indented so it lands inside `binds { }`. Mod+N hides/shows the keyboard,
  # which is the only way to get it out of the way when the Type Cover is on.
  # Plain string on purpose: Nix strips the common indentation out of
  # indented strings, which would take the intended indent with it.
  tabletBinds = lib.optionalString tablet
    "\n    Mod+N { spawn \"wvkbd-toggle\"; }\n";

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
