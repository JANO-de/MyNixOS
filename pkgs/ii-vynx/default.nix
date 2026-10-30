# ii-vynx: Quickshell config for Hyprland (github.com/vaguesyntax/ii-vynx, GPL-3.0).
# Upstream has no flake and no usable Nix packaging (sdata/dist-nix is not for NixOS).
# We install the config trees only; modules/desktop/shells/ii.nix seeds them into $HOME.
# Update: bump `rev`, set `hash = lib.fakeHash`, build, paste the real hash.
{ lib, pkgs, stdenv, fetchFromGitHub, ... }:
let
  shapes = pkgs.callPackage ../ii-shapes.nix { };
in
stdenv.mkDerivation {
  pname = "ii-vynx";
  version = "unstable-2026-09-19";
  src = fetchFromGitHub {
    owner = "vaguesyntax";
    repo = "ii-vynx";
    rev = "9cdec0d195dbbbe94624630442d6dceffd88e672";
    hash = "sha256-1/aizHQo/eUBbGsTG+Lbpx/ix4XfRbz31r5gQeQQfPA=";
  };
  dontBuild = true;
  dontPatchShebangs = true;
  installPhase = ''
    mkdir -p $out/share/quickshell/ii
    cp -r dots/.config/quickshell/ii/* $out/share/quickshell/ii/
    rm -rf $out/share/quickshell/ii/modules/common/widgets/shapes
    mkdir -p $out/share/quickshell/ii/modules/common/widgets/shapes
    cp -r ${shapes}/* $out/share/quickshell/ii/modules/common/widgets/shapes/

    mkdir -p $out/share/hypr/ii
    cp -r dots/.config/hypr/* $out/share/hypr/ii/

    mkdir -p $out/share/matugen/ii
    cp -r dots/.config/matugen/* $out/share/matugen/ii/
  '';
  meta = {
    description = "ii-vynx Quickshell config";
    homepage = "https://github.com/vaguesyntax/ii-vynx";
    license = lib.licenses.gpl3Plus;
  };
}
