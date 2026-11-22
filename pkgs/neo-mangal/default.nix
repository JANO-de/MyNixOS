# neo-mangal package (Rust, ratatui + vendored Lua 5.4). `src` is the flake input neo-mangal-src.
# Kindle/EPUB/MOBI output also needs kcc-c2e and kindlegen on PATH; CBZ and PDF work without them.
{
  lib,
  rustPlatform,
  src,
}:

rustPlatform.buildRustPackage {
  pname = "neo-mangal";
  version = "1.0.0";
  inherit src;

  cargoLock.lockFile = src + "/Cargo.lock";

  doCheck = false;

  # Same shortcuts the upstream Makefile creates.
  postInstall = ''
    ln -s $out/bin/neo-mangal $out/bin/nmangal
    ln -s $out/bin/neo-mangal $out/bin/neomangal
  '';

  meta = {
    description = "Manga TUI downloader and KCC processor";
    homepage = "https://github.com/kalebhenrique/neo-mangal";
    license = lib.licenses.mit;
    mainProgram = "neo-mangal";
  };
}
