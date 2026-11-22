{ runCommandLocal }:
runCommandLocal "n-murder-drones-cursors" { } ''
  mkdir -p $out/share/icons
  cp -r ${../assets/cursors/N-Murder-Drones} $out/share/icons/N-Murder-Drones
''
