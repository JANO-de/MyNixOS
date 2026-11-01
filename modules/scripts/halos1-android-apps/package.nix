# Runs the script ON halos1: it is piped through ssh (default host alias: halos1).
{ pkgs, repoPath }:
pkgs.writeShellScriptBin "halos1-android-apps" ''
  exec ${pkgs.openssh}/bin/ssh "''${1:-halos1}" 'bash -s' < ${./halos1-android-apps.sh}
''
