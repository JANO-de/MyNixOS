{
  config,
  pkgs,
  lib,
  theme,
  ...
}:

let
  content = lib.replaceStrings
    [ "@FOCUS@" "@FOCUS_INACTIVE@" ]
    [
      (theme.color "accent")
      (theme.color "surface")
    ]
    (builtins.readFile ./niri/inir-config.kdl);
in
{
  xdg.configFile."niri/config.kdl" = {
    source = pkgs.runCommand "niri-config-validated" {
      nativeBuildInputs = [ pkgs.niri ];
    } ''
      cat > config.kdl <<'KDLEOF'
      ${content}
      KDLEOF
      niri validate --config config.kdl
      cp config.kdl $out
    '';
  };
}
