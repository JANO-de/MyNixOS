# vid-dl: prebuilt PyInstaller onedir bundle, run unmodified inside an FHS env.
# One-time: nix-store --add-fixed sha256 ~/Descargas/Linux_x64-portable.zip
{
  stdenvNoCC,
  requireFile,
  unzip,
  buildFHSEnv,
}:
let
  unpacked = stdenvNoCC.mkDerivation {
    pname = "vid-dl-unpacked";
    version = "portable";
    src = requireFile {
      name = "Linux_x64-portable.zip";
      hash = "sha256-dCpwrcVuI5YEV/3rMnTdqf3u2nHYsyD7ppj8NVcGSAU=";
      message = "Run: nix-store --add-fixed sha256 /path/to/Linux_x64-portable.zip";
    };
    nativeBuildInputs = [ unzip ];
    dontFixup = true; # patchelf would corrupt the PyInstaller archive
    unpackPhase = "unzip -q $src";
    installPhase = ''
      mkdir -p $out/share
      cp -r vid-dl $out/share/vid-dl
      chmod +x $out/share/vid-dl/vid-dl
    '';
  };
in
buildFHSEnv {
  name = "vid-dl";
  targetPkgs =
    p: with p; [
      zlib
      openssl
      stdenv.cc.cc.lib
      ffmpeg
    ];
  runScript = "${unpacked}/share/vid-dl/vid-dl";
  meta.mainProgram = "vid-dl";
}
