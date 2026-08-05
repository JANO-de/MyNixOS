{ config, pkgs, lib, ... }:

{
  # niri config, validated against the installed niri version at build time
  xdg.configFile."niri/config.kdl" = {
    source = pkgs.runCommand "niri-config-validated" {
      nativeBuildInputs = [ pkgs.niri ];
    } ''
      niri validate --config ${./niri/config.kdl}
      cp ${./niri/config.kdl} $out
    '';
  };
}
