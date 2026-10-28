{ pkgs, ... }:
pkgs.runCommand "nixscout-index" {
  nativeBuildInputs = [ pkgs.niXscout or (pkgs.callPackage ./default.nix {}) ];
} ''
  mkdir -p $out/share/nixscout
  if command -v niXscout-index >/dev/null 2>&1; then
    niXscout-index ${./data} $out/share/nixscout/index.sqlite ${toString ../flake.lock}
  else
    touch $out/share/nixscout/index.sqlite
  fi
''
