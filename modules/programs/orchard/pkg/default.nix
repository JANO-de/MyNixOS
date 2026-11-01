# Orchard package (Qt6/QML app). Built via cargo + meson + npm.
{
  lib,
  pkgs,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  cmake,
  pkg-config,
  nodejs,
  python3,
  rustc,
  cargo,
  qt6,
  ffmpeg,
  alsa-lib,
  libpulseaudio,
  vulkan-loader,
  libGL,
  wayland,
  libxkbcommon,
  libsecret,
  glib,
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
  youtubeSrc =
    pkgs.runCommand "orchard-youtube-src" { }
      "mkdir -p $out; cp ${source}/providers/youtube/package.json ${source}/providers/youtube/package-lock.json $out/";
  npmDepsFixed = pkgs.fetchNpmDeps {
    src = youtubeSrc;
    hash = "sha256-AzFvOzfhj3Sa7GPnRpDOC00HsYYoycsQTsHnEeyL4Nc=";
  };
  qmlcachegenBin = pkgs.writeShellScriptBin "qmlcachegen" "exec /nix/store/fshbn5kc9yg839ns0fry5v64vx7q0y4x-orchard-qt-6.11.2/libexec/qmlcachegen \"$@\"";
  qmltyperegistrarBin = pkgs.writeShellScriptBin "qmltyperegistrar" "exec /nix/store/fshbn5kc9yg839ns0fry5v64vx7q0y4x-orchard-qt-6.11.2/libexec/qmltyperegistrar \"$@\"";
  desktopItem = pkgs.makeDesktopItem {
    name = "orchard";
    desktopName = "Orchard";
    exec = "orchard";
    icon = "orchard";
    categories = [
      "AudioVideo"
      "Audio"
      "Player"
    ];
  };
in

stdenv.mkDerivation rec {
  pname = "orchard";
  version = "1.0.0-canary.10";

  src = source;
  npmDeps = npmDepsFixed;
  cargoDeps = cargoDepsFixed;

  nativeBuildInputs = [
    mesonBin
    qmlcachegenBin
    qmltyperegistrarBin
    cargoWrapper
    meson
    ninja
    cmake
    pkg-config
    nodejs
    python3
    rustToolchain
    pkgs.llvmPackages.libclang
    pkgs.rustPlatform.cargoSetupHook
    pkgs.npmHooks.npmConfigHook
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtmultimedia
    qt6.qtwebview
    qt6.qtwebengine
    qt6.qtwebsockets
    qt6.qtwayland
    qt6.qtsvg
    qt6.qtshadertools
    ffmpeg
    alsa-lib
    libpulseaudio
    vulkan-loader
    libGL
    wayland
    libxkbcommon
    libsecret
    glib
    pkgs.libx11
    pkgs.libxext
    pkgs.libxcb
  ];

  mesonBuildType = "release";
  npmRoot = "providers/youtube";
  LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
  qtWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    "${ffmpeg}/bin"
  ];
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

  postInstall = ''
    install -Dm644 ${source}/app/qml/assets/orchard-logo.png $out/share/icons/hicolor/256x256/apps/orchard.png
    install -Dm644 ${desktopItem}/share/applications/orchard.desktop $out/share/applications/orchard.desktop
    install -Dm755 ${source}/vendor/discord_social_sdk/lib/linux/libdiscord_partner_sdk.so $out/lib/libdiscord_partner_sdk.so
  '';

  postFixup = ''
    for bin in .orchard-wrapped .orchard-auth-helper-wrapped; do
      ${pkgs.patchelf}/bin/patchelf --add-rpath "${
        lib.makeLibraryPath [
          qt6.qtbase
          qt6.qtdeclarative
          qt6.qtmultimedia
          qt6.qtwebview
          qt6.qtwebengine
          qt6.qtwebsockets
          qt6.qtwayland
          qt6.qtsvg
          qt6.qtshadertools
          ffmpeg
          alsa-lib
          libpulseaudio
          vulkan-loader
          libGL
          wayland
          libxkbcommon
          libsecret
          glib
          pkgs.libx11
          pkgs.libxext
          pkgs.libxcb
          pkgs.stdenv.cc.cc
        ]
      }:$out/lib" "$out/bin/$bin"
    done
    ${pkgs.patchelf}/bin/patchelf --add-rpath "${
      lib.makeLibraryPath [
        alsa-lib
        libpulseaudio
        pkgs.libx11
        pkgs.stdenv.cc.cc
      ]
    }:$out/lib" "$out/lib/libdiscord_partner_sdk.so"
  '';

  meta = {
    description = "Orchard music client";
    homepage = "https://github.com/SFG5453/Orchard";
    license = with lib.licenses; [
      agpl3Plus
      {
        fullName = "PolyForm Shield 1.0.0";
        free = false;
      }
    ];
  };
}
