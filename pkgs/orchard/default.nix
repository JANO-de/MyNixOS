{ lib, pkgs, stdenv, fetchFromGitHub, meson, ninja, cmake, pkg-config, nodejs, python3, rustc, cargo
, qt6, ffmpeg, alsa-lib, libpulseaudio, vulkan-loader, libGL, wayland, libxkbcommon, libsecret, glib
}:

let
  meson12 = pkgs.fetchzip {
    url = "https://github.com/mesonbuild/meson/releases/download/1.12.0/meson-1.12.0.tar.gz";
    sha256 = "sha256-mY8LTnQ/YHbv5XiXDXayN35V7qdC+dKpOn/ePPXj9Os=";
  };
  mesonBin = pkgs.writeShellScriptBin "meson" "exec ${python3}/bin/python3 ${meson12}/meson.py \"$@\"";
  cargoWrapper = pkgs.writeShellScriptBin "cargo" "export LIBCLANG_PATH=${pkgs.llvmPackages.libclang.lib}/lib; exec ${pkgs.rust-bin.stable.latest.default}/bin/cargo \"$@\"";
  source = fetchFromGitHub {
    owner = "SFG5453";
    repo = "Orchard";
    rev = "a009b28c9c2c3888d20e28119efea1d58297730d";
    fetchSubmodules = true;
    hash = "sha256-Jvp//VqimE/vNr2MFDlOEg5CVb7Ee4DvE62kY+tT57E=";
  };
  rustToolchain = pkgs.rust-bin.stable.latest.default;
  cargoDepsFixed = pkgs.rustPlatform.importCargoLock {
    lockFile = source + "/Cargo.lock";
  };
  youtubeSrc = pkgs.runCommand "orchard-youtube-src" {} "mkdir -p $out; cp ${source}/providers/youtube/package.json ${source}/providers/youtube/package-lock.json $out/";
  npmDepsFixed = pkgs.fetchNpmDeps {
    src = youtubeSrc;
    hash = "sha256-AzFvOzfhj3Sa7GPnRpDOC00HsYYoycsQTsHnEeyL4Nc=";
  };
  qmlcachegenBin = pkgs.writeShellScriptBin "qmlcachegen" "exec /nix/store/fshbn5kc9yg839ns0fry5v64vx7q0y4x-orchard-qt-6.11.2/libexec/qmlcachegen \"$@\"";
  qmltyperegistrarBin = pkgs.writeShellScriptBin "qmltyperegistrar" "exec /nix/store/fshbn5kc9yg839ns0fry5v64vx7q0y4x-orchard-qt-6.11.2/libexec/qmltyperegistrar \"$@\"";
in

stdenv.mkDerivation rec {
  pname = "orchard";
  version = "1.0.0-canary.10";

  src = source;
  npmDeps = npmDepsFixed;
  cargoDeps = cargoDepsFixed;

  nativeBuildInputs = [
    mesonBin qmlcachegenBin qmltyperegistrarBin cargoWrapper meson ninja cmake pkg-config nodejs python3 rustToolchain pkgs.llvmPackages.libclang pkgs.rustPlatform.cargoSetupHook pkgs.npmHooks.npmConfigHook
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase qt6.qtdeclarative qt6.qtmultimedia qt6.qtwebview qt6.qtwebengine qt6.qtwebsockets
    qt6.qtwayland qt6.qtsvg qt6.qtshadertools
    ffmpeg alsa-lib libpulseaudio vulkan-loader libGL wayland libxkbcommon libsecret glib pkgs.xorg.libX11 pkgs.xorg.libXext
  ];

  mesonBuildType = "release";
  npmRoot = "providers/youtube";
  LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
  preConfigure = "export PATH=${pkgs.qt6.qtdeclarative}/libexec:$PATH; export LIBCLANG_PATH=${pkgs.llvmPackages.libclang.lib}/lib";
  postPatch = ''
    python3 - <<PY
    libdir = "${pkgs.llvmPackages.libclang.lib}/lib"
    p = "scripts/meson-cargo-build.py"
    s = open(p).read()
    s = s.replace("import subprocess", "import os\nos.environ['LIBCLANG_PATH'] = '" + libdir + "'\nimport subprocess", 1)
    open(p, "w").write(s)
    PY
    # disable network-dependent adaptive mix staging
    python3 - <<PY2
    import re
    q = open('meson.build').read()
    q = re.sub(r'adaptive_stage = custom_target\(.*?build_by_default: true\)', 'adaptive_stage = []', q, count=1, flags=re.S)
    open('meson.build','w').write(q)
    PY2
  '';
  dontUseCmakeConfigure = true;
  NIX_LDFLAGS = "-lasound -lpulse -lX11 -lXext";

  meta = {
    description = "Orchard music client";
    homepage = "https://github.com/SFG5453/Orchard";
    license = with lib.licenses; [ agpl3Plus ];
  };
}
