# ii-vynx: Quickshell config for Hyprland (github.com/JANO-de/ii-halos, GPL-3.0).
# Fork of illogical-impulse. We install the config trees only; modules/desktop/shells/ii.nix seeds them into $HOME.
# Update: bump `rev`, set `hash = lib.fakeHash`, build, paste the real hash.
{ lib, pkgs, stdenv, fetchFromGitHub, ... }:
let
  shapes = pkgs.callPackage ../ii-shapes.nix { };
in
stdenv.mkDerivation {
  pname = "ii-vynx";
  version = "unstable-2026-10-30";
  src = fetchFromGitHub {
    owner = "JANO-de";
    repo = "ii-halos";
    rev = "a0c1f9df36d000ebca544aacb8d25a282ca90997";
    hash = lib.fakeHash;
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
