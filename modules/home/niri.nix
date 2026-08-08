{
  config,
  pkgs,
  lib,
  theme,
  ...
}:

let
  # Inject theme colors and Tide Island store paths into the static KDL template
  content = lib.replaceStrings
    [ "@FOCUS@" "@FOCUS_INACTIVE@" "@QUICKSHELL_BIN@" "@TIDE_QML_DIR@" ]
    [
      (theme.color "accent")
      (theme.color "surface")
      "${pkgs.quickshell}/bin/quickshell"
      "${pkgs.tide-island}/share/tide-island"
    ]
    (builtins.readFile ./niri/config.kdl);
in
{
  # niri config, validated against the installed niri version at build time.
  # Colors come from the central theme (modules/theme.nix).
  xdg.configFile."niri/config.kdl" = {
    source = pkgs.runCommand "niri-config-validated" {
      nativeBuildInputs = [ pkgs.niri ];
    } ''
      cat > config.kdl <<'EOF'
      ${content}
      EOF
      niri validate --config config.kdl
      cp config.kdl $out
    '';
  };
}
