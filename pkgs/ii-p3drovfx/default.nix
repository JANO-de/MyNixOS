{ lib, pkgs, stdenv, fetchFromGitHub, ... }:

# ii-p3drovfx: Quickshell config for Hyprland (desktop/laptop only).
# Upstream has no flake; we install the config tree. Matugen 4.1.0+ required
# (nixpkgs has 4.0.0; using pkgs.matugen as fallback - ASK resolved: overlay preferred).
stdenv.mkDerivation {
  pname = "ii";
  version = "unstable";
  src = fetchFromGitHub {
    owner = "P3DROVFX";
    repo = "ii-p3drovfx";
    rev = "main";
    hash = "sha256-2Kp651Eof9uWhhzRNjGl7Gmd8aoJjVO1ahCqLI5gHzg=";
  };
  dontBuild = true;
  dontPatchShebangs = true;
  installPhase = ''
    mkdir -p $out/share/quickshell/ii
    cp -r dots/.config/quickshell/ii/* $out/share/quickshell/ii/
  '';
  meta = {
    description = "ii Quickshell config (P3DROVFX fork)";
    license = lib.licenses.gpl3Plus;
    mainProgram = "ii";
  };
}
