## modules/home/end4-pc.nix
##
## Home-Manager module for end4-pC (https://github.com/pctrade/end4-pC),
## a Quickshell desktop shell config, on niri.
##
## IMPORTANT CONTEXT (read this before assuming this file "ports" the shell):
## end4-pC is a fork of end-4/dots-hyprland. As of the commit pinned below,
## the upstream QML *already ships a compositor abstraction layer*
## (services/WM.qml -> HyprlandBackend.qml / NiriBackend.qml) with a working,
## niri-msg-based backend, a niri-aware Overview component
## (modules/ii/overview/NiriOverview.qml), niri-aware night-light handling
## (services/Hyprsunset.qml falls back to wlsunset when WM.compositor == "niri"),
## and IpcHandler targets on every panel so keybinds can be wired from
## niri's config.kdl instead of Hyprland dispatchers.
##
## In other words: there is no QML left to rewrite for basic niri support.
## What's actually missing to run it declaratively on NixOS is (a) fetching
## and placing the config directory, (b) the runtime dependencies it shells
## out to, and (c) niri keybinds calling its IPC targets. That's what this
## file and niri-end4pc-keybinds.kdl do.
##
## Known real gap: modules/ii/settings/pages/NiriConfig.qml edits
## ~/.config/niri/config.kdl directly with sed-like shell commands so its
## in-app "Settings" panel can rewrite your keybinds live. Your niri config
## is generated read-only from the Nix store (modules/home/niri.nix), so
## that specific in-app editor won't be able to persist changes -- editing
## config.kdl in git and rebuilding is still required. Everything else
## (theme, wallpaper, panels, bar, blur, etc.) is unaffected by this.

{ config, pkgs, lib, ... }:

let
  end4pcSrc = pkgs.fetchFromGitHub {
    owner = "pctrade";
    repo = "end4-pC";
    # Pinned to the commit analyzed for this module. Bump freely; the
    # compositor-abstraction files referenced above are what to check
    # for regressions if you update.
    rev = "7ec99ebcba9c56134484e80a6c1c0d0cd8f5db21";
    hash = "sha256-XLlcB0ZIFkP7BGBZEcp7zTcMMmtnSWP4Sqio+NWe1rs=";
  };

  # Pinned source + the niri keybind-lookup additions from ./end4-pc/
  # (niri parser script, NiriKeybinds.qml service, LauncherSearch patch).
  end4pcSrcPatched = pkgs.runCommand "end4-pc-niri-patched" { } ''
    cp -r ${end4pcSrc} $out
    chmod -R u+w $out
    patch -d $out -p1 < ${./end4-pc/launcher-search-keybinds.patch}
    cp ${./end4-pc/services/NiriKeybinds.qml} $out/services/NiriKeybinds.qml
    mkdir -p $out/scripts/niri
    cp ${./end4-pc/scripts/niri/get_keybinds.py} $out/scripts/niri/get_keybinds.py
    chmod +x $out/scripts/niri/get_keybinds.py
  '';

  # Best-effort Python env for scripts/colors/generate_colors_material.py
  # and friends (Material You palette generation, thumbnails, lyrics).
  # materialyoucolor IS packaged in nixpkgs as of late 2025. If any of
  # these names have moved/been renamed by the time you build, run
  # `nix search nixpkgs <name>` and fix the list -- don't just delete
  # entries, or theming/wallpaper color extraction will silently fail.
  end4pcPython = pkgs.python3.withPackages (ps: with ps; [
    pillow
    loguru
    materialyoucolor
    tqdm
    click
    numpy
    pygobject3
    opencv4
    google-auth
  ]);
in
{
  # --- Runtime dependencies end4-pC shells out to -----------------------
  # quickshell itself, niri, fuzzel, swaybg, brightnessctl and playerctl
  # are already provided by modules/desktop/niri.nix in this flake.
  home.packages = with pkgs; [
    # Wrapper around quickshell's `qs` that adds the Qt5Compat QML module
    # path (QtQuick.GraphicalEffects and friends, used heavily by end4-pC's
    # QML). Without it, `qs -c end4-pC` fails with
    # "module Qt5Compat.GraphicalEffects is not installed".
    (writeShellScriptBin "qs" ''
      export QML_IMPORT_PATH="${qt6.qt5compat}/lib/qt-6/qml:${qt6.qtpositioning}/lib/qt-6/qml:${kdePackages.syntax-highlighting}/lib/qt-6/qml:${kdePackages.kirigami.unwrapped}/lib/qt-6/qml''${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
      exec ${quickshell}/bin/qs "$@"
    '')

    end4pcPython

    # Screenshots / region select (modules/ii/regionSelector)
    grim
    slurp
    satty

    # Clipboard manager (services/Cliphist.qml)
    cliphist
    wl-clipboard

    # Material You / app theming pipeline (services/SystemTheming.qml,
    # scripts/colors/switchwall.sh calls both matugen and the python
    # script above)
    matugen

    # Night light on niri (services/Hyprsunset.qml uses this instead of
    # hyprsunset when WM.compositor == "niri")
    wlsunset

    # Notifications used by shell scripts via notify-send in addition to
    # Quickshell's own notification server
    libnotify

    # GTK/Qt/icon theme switching + Kvantum recoloring scripts
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugin-kvantum
    kdePackages.qtstyleplugin-kvantum

    # Fonts the default theme expects
    material-symbols
    nerd-fonts.jetbrains-mono
    readexpro
  ];

  # --- The shell config itself -------------------------------------------
  # Placed as end4-pC (matching `qs -c end4-pC` from the upstream README)
  # alongside, not replacing, any other quickshell config you keep here
  # (e.g. Tide Island).
  #
  # end4-pC ships keybind lookup only for Hyprland (HyprlandKeybinds.qml +
  # scripts/hyprland/get_keybinds.py), so on niri the "<" launcher prefix
  # came up empty. The `end4-pc/` dir next to this file adds the niri
  # equivalent (scripts/niri/get_keybinds.py + services/NiriKeybinds.qml)
  # and patches LauncherSearch.qml to pick them when WM.compositor == niri.
  xdg.configFile."quickshell/end4-pC" = {
    source = end4pcSrcPatched;
    recursive = true;
  };

  # NOTE: this flake does NOT use Home Manager's `wayland.windowManager.niri`
  # module -- modules/home/niri.nix hand-templates config.kdl from
  # modules/home/niri/config.kdl instead. So autostart and keybinds for
  # end4-pC are NOT set here. Instead:
  #   1. Append the contents of niri-end4pc-keybinds.kdl (next to this file)
  #      into modules/home/niri/config.kdl.
  #   2. See README.md step 3 for exactly what to paste and where.
}
