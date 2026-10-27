{ lib, pkgs, ... }:

pkgs.rustPlatform.buildRustPackage {
  pname = "nixscout";
  version = "0.1.0";
  src = ./.;
  cargoLock = { lockFile = ./Cargo.lock; };
  nativeBuildInputs = [ pkgs.pkg-config ];
  buildInputs = [ pkgs.gtk4 pkgs.libadwaita pkgs.glib pkgs.sqlite ];
  meta = {
    description = "Read-only browser for the Nix world";
    mainProgram = "nixscout";
    license = lib.licenses.mit;
  };
}
