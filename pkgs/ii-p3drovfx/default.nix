{ lib, pkgs, stdenv, fetchFromGitHub, ... }:

# ii-p3drovfx: Quickshell config for Hyprland (desktop/laptop only).
# Upstream has no flake; we install the config tree. Matugen 4.1.0+ required
# (nixpkgs has 4.0.0; using pkgs.matugen as fallback - ASK resolved: overlay preferred).
let
  roundedPolygon = pkgs.fetchzip {
    url = "https://github.com/end-4/rounded-polygon-qmljs/archive/refs/heads/main.tar.gz";
    hash = "sha256-p1Ia0oQCWnik2saVMgv7IABkaJV43PoY7uuwXjXlc+Q=";
  };
in
stdenv.mkDerivation {
  pname = "ii";
  version = "unstable";
  src = fetchFromGitHub {
    owner = "P3DROVFX";
    repo = "ii-p3drovfx";
    rev = "3e9f4c0aca3b1efb546fa96f7348fba24bd3de47";
    hash = "sha256-/H4cxah2U6wOgKtkaCweaVOQl/jl2wplQyeJxN6QUa4=";
  };
  dontBuild = true;
  dontPatchShebangs = true;
  installPhase = ''
    mkdir -p $out/share/quickshell/ii
    cp -r dots/.config/quickshell/ii/* $out/share/quickshell/ii/
    rm -rf $out/share/quickshell/ii/modules/common/widgets/shapes
    mkdir -p $out/share/quickshell/ii/modules/common/widgets/shapes
    cp -r ${roundedPolygon}/* $out/share/quickshell/ii/modules/common/widgets/shapes/

    mkdir -p $out/share/hypr/ii
    cp -r dots/.config/hypr/* $out/share/hypr/ii/
    sed -i 's/render_power = 10,/render_power = 4,/' $out/share/hypr/ii/hyprland/general.lua

    mkdir -p $out/share/matugen/ii
    cp -r dots/.config/matugen/* $out/share/matugen/ii/
  '';
  meta = {
    description = "ii Quickshell config (P3DROVFX fork)";
    license = lib.licenses.gpl3Plus;
    mainProgram = "ii";
  };
}
