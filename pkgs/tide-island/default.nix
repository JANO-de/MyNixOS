{ lib, stdenv, cmake, ninja, pkg-config, makeWrapper, qt6, quickshell, udev, libGL, python3
, src
}:

stdenv.mkDerivation {
  pname = "tide-island";
  version = "1.0.35";

  inherit src;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    makeWrapper
    qt6.wrapQtAppsHook
    python3
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtwayland
    qt6.qt5compat
    qt6.qtshadertools
    qt6.qtsvg
    libGL
    udev
    quickshell
  ];

  cmakeFlags = [
    "-DCMAKE_INSTALL_LIBDIR=lib"
  ];

  doCheck = false;

  postPatch = ''
    substituteInPlace tide-island-launcher \
      --replace-fail "/usr/bin/quickshell" "${quickshell}/bin/quickshell"
  '';

  postInstall = ''
    substituteInPlace "$out/lib/systemd/user/tide-island.service" \
      --replace-fail "/usr/bin/tide-island" "$out/bin/tide-island"
    substituteInPlace "$out/share/applications/tide-island.desktop" \
      --replace-fail "/usr/bin/tide-island" "$out/bin/tide-island"
  '';

  postFixup = ''
    wrapProgram "$out/bin/tide-island" \
      --prefix QML_IMPORT_PATH : "$out/lib/qt6/qml" \
      --prefix QML_IMPORT_PATH : "${qt6.qtdeclarative}/lib/qt6/qml" \
      --prefix QML_IMPORT_PATH : "${qt6.qt5compat}/lib/qt6/qml"
  '';

  meta = {
    description = "Smooth, lightweight, and flexible interactive Dynamic Island for Hyprland and niri";
    homepage = "https://github.com/enhaoswen/Tide-island";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
