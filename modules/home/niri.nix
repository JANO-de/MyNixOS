{
  pkgs,
  lib,
  theme,
  ...
}:

let
  # Inject theme colors into the static KDL template
  content = lib.replaceStrings
    [ "@FOCUS@" "@FOCUS_INACTIVE@" ]
    [
      (theme.color "accent")
      (theme.color "surface")
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
