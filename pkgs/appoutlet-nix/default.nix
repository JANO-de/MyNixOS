{ lib, pkgs, buildNpmPackage, electron, makeWrapper }:

buildNpmPackage {
  pname = "appoutlet-nix";
  version = "2.1.0";
  src = /home/jano/src/appoutlet-nix;
  npmDepsHash = "sha256-AQUZHqF1nt/3Y/5XkD4OA5XjrLJrDvOcCyjuUnDUYFk=";
  npmDepsFetcherVersion = 2;
  npmFlags = [ "--legacy-peer-deps" ];
  npmInstallFlags = [ "--omit=optional" "--legacy-peer-deps" ];
  npmBuildScript = "build:angular";

  nativeBuildInputs = [ pkgs.makeWrapper ];
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/appoutlet
    cp -r dist $out/lib/appoutlet/
    cp main.js preload.js $out/lib/appoutlet/
    cp -r core $out/lib/appoutlet/
    runHook postInstall
  '';
  postFixup = ''
    makeWrapper ${electron}/bin/electron $out/bin/appoutlet-nix \
      --add-flags "$out/lib/appoutlet/main.js" \
      --add-flags "--no-sandbox"
  '';
  meta = {
    description = "Nix-native app store (AppOutlet fork)";
    license = lib.licenses.mit;
  };
}
