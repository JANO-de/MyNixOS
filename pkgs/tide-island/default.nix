{
  lib,
  stdenv,
  cmake,
  ninja,
  pkg-config,
  makeWrapper,
  qt6,
  quickshell,
  udev,
  libGL,
  python3,
  niri,
  src,
  theme,
}:

let
  p = theme.palette;

  # Map Tide Island's hardcoded UI colors to the central theme palette.
  # Keys are the upstream "Claude web" / iOS-like colors in Theme.qml
  # (config app) and StyleTokensBackend.cpp (control center).
  mapping = {
    # Theme.qml — config app
    "#20201f" = p.base;
    "#181817" = p.mantle;
    "#2c2c2a" = p.surface0;
    "#474744" = p.surface1;
    "#282827" = p.surface0;
    "#3d3d3b" = p.surface1;
    "#5a5a57" = p.surface2;
    "#d97757" = p.mauve;
    "#59382f" = p.surface1;
    "#f9f9f7" = p.text;
    "#c3c2b7" = p.subtext0;
    "#97958d" = p.overlay1;
    "#c6613f" = p.lavender;
    "#ad5235" = p.overlay2;
    "#141413" = p.crust;
    "#383835" = p.surface1;
    "#454543" = p.surface2;
    "#483831" = p.surface0;
    "#3c0e0e" = "#33243c"; # error bg: dark mauve tint
    "#641919" = p.surface1;
    "#f4abab" = p.red;

    # StyleTokensBackend.cpp — control center
    "#1c1c1e" = p.mantle;
    "#232326" = p.surface0;
    "#2c2c2e" = p.surface0;
    "#26272b" = p.surface0;
    "#222327" = p.surface0;
    "#343437" = p.surface0;
    "#3a3a3d" = p.surface1;
    "#323236" = p.surface0;
    "#212226" = p.mantle;
    "#3f4046" = p.surface1;
    "#4a4b50" = p.surface1;
    "#f5f5f7" = p.text;
    "#f7f8fb" = p.text;
    "#8e8e93" = p.subtext0;
    "#9b9da4" = p.subtext0;
    "#9da0a8" = p.subtext0;
    "#7f828a" = p.overlay1;
    "#878a92" = p.surface2;
    "#8f9198" = p.overlay1;
    "#b5b7bf" = p.subtext1;
    "#0a84ff" = p.mauve;
    "#0066d6" = p.lavender;
    "#6ea8ff" = p.mauve;
    "#34c759" = p.green;
    "#ffcc00" = p.yellow;
    "#ff3b30" = p.red;
    "#ff7c72" = p.red;
    "#868991" = p.surface2;
    "#63656c" = p.surface1;
    "#e9e9ec" = p.subtext0;
    "#ee17181b" = "#ee${lib.removePrefix "#" p.base}";
    "#ff202226" = "#ff${lib.removePrefix "#" p.base}";
    "#ff2b2d34" = "#ff${lib.removePrefix "#" p.surface0}";
    "#73d4ff" = p.mauve;
  };
in

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
    niri
  ];

  cmakeFlags = [
    "-DCMAKE_INSTALL_LIBDIR=lib"
  ];

  doCheck = false;

  postPatch = ''
    substituteInPlace tide-island-launcher \
      --replace-fail "/usr/bin/quickshell" "${quickshell}/bin/quickshell"

    cat > patch-theme-mapping.json <<'JSON'
    ${builtins.toJSON mapping}
    JSON
    python3 ${./patch-theme.py} patch-theme-mapping.json \
      Tide-island-app/Theme.qml \
      backend/StyleTokensBackend.cpp
  '';

  postInstall = ''
    substituteInPlace "$out/lib/systemd/user/tide-island.service" \
      --replace-fail "/usr/bin/tide-island" "$out/bin/tide-island"
    substituteInPlace "$out/share/applications/tide-island.desktop" \
      --replace-fail "/usr/bin/tide-island" "$out/bin/tide-island"
  '';

  postFixup = ''
    wrapProgram "$out/bin/tide-island" \
      --prefix PATH : "${niri}/bin" \
      --prefix QML_IMPORT_PATH : "$out/lib/qt6/qml" \
      --prefix QML_IMPORT_PATH : "${qt6.qtdeclarative}/lib/qt-6/qml" \
      --prefix QML_IMPORT_PATH : "${qt6.qt5compat}/lib/qt-6/qml"
  '';

  meta = {
    description = "Smooth, lightweight, and flexible interactive Dynamic Island for Hyprland and niri";
    homepage = "https://github.com/enhaoswen/Tide-island";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
