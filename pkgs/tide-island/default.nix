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
  awww,
  dbus,
  pipewire,
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

    # NixOS has no /usr/bin/quickshell or /usr/share/tide-island: inject the
    # store paths used by the config app's generated shortcut files.
    substituteInPlace Tide-island-app/backend.cpp \
      --replace-fail "/usr/bin/quickshell" "${quickshell}/bin/quickshell" \
      --replace-fail "/usr/share/tide-island" "$out/share/tide-island"

    substituteInPlace Tide-island-app/Shortcut.qml \
      --replace-fail "/usr/bin/quickshell" "${quickshell}/bin/quickshell" \
      --replace-fail "/usr/share/tide-island" "$out/share/tide-island"

    substituteInPlace backend/SysBackend.cpp \
      --replace-fail "/usr/share/tide-island/bin/lyricsmpris" "$out/share/tide-island/bin/lyricsmpris"

    # The bundled launcher rewrites ~/.config/niri/config.kdl with an include of
    # its shortcut file. On NixOS that file is a declarative read-only store
    # symlink, so never run --ensure-niri-shortcuts. Binds are declared in
    # modules/home/niri/config.kdl instead.
    substituteInPlace tide-island-launcher \
      --replace-fail '"$CONFIG_APP" --ensure-niri-shortcuts || true' 'true # niri shortcuts are managed declaratively in the NixOS niri config'

    # Keep the config app from rewriting the main niri config when the user
    # clicks "Apply" on the shortcut page; only write the reference file.
    python3 - <<'PY'
    path = "Tide-island-app/backend.cpp"
    text = open(path).read()
    start = text.index("    if (includePresent)\n")
    anchor = text.index("QSaveFile outputConfig(mainConfigInfo.absoluteFilePath());", start)
    end = text.index("\n}", anchor) + 2
    new_tail = (
        "    // NixOS: the main niri config is a declarative, read-only home-manager\n"
        "    // store symlink. Only write the reference shortcut file; actual niri\n"
        "    // binds are declared in modules/home/niri/config.kdl, not via include.\n"
        "    (void)managedIncludeLine;\n"
        "    return true;\n"
        "}\n"
    )
    text = text[:start] + new_tail + text[end:]
    open(path, "w").write(text)
    PY

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
    substituteInPlace "$out/share/applications/tide-island-config.desktop" \
      --replace-fail "/usr/bin/tide-island-config-app" "$out/bin/tide-island-config-app"
  '';

  postFixup = ''
    wrapProgram "$out/bin/tide-island" \
      --prefix PATH : "$out/bin" \
      --prefix PATH : "${niri}/bin" \
      --prefix PATH : "${awww}/bin" \
      --prefix PATH : "${python3}/bin" \
      --prefix PATH : "${dbus}/bin" \
      --prefix PATH : "${pipewire}/bin" \
      --prefix PATH : "/run/current-system/sw/bin" \
      --prefix PATH : "/run/current-system/sw/sbin" \
      --prefix PATH : "/etc/profiles/per-user/jano/bin" \
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
