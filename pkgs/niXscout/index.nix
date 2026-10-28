{ pkgs, ... }:
pkgs.runCommand "nixscout-index" { } ''
  mkdir -p $out/share/nixscout
  touch $out/share/nixscout/index.sqlite
''
