{ config, pkgs, lib, ... }:

let
  inirSrc = pkgs.fetchFromGitHub {
    owner = "snowarch";
    repo = "inir";
    rev = "f1e8a6ee5283a51640e715fc083881d88e02a5bf";
    hash = "sha256-159pMRQZZKzbYBzGwJUlEYhtIulGb6bNG1i04NbPHkg=";
  };

  inirPython = pkgs.python3.withPackages (ps: with ps; [
    pillow
    loguru
    materialyoucolor
    tqdm
    click
    numpy
    pygobject3
    opencv4
    google-auth
    requests
    beautifulsoup4
  ]);

  qtImportPaths = "${pkgs.qt6.qt5compat}/lib/qt-6/qml:${pkgs.qt6.qtpositioning}/lib/qt-6/qml:${pkgs.kdePackages.syntax-highlighting}/lib/qt-6/qml:${pkgs.kdePackages.kirigami.unwrapped}/lib/qt-6/qml";

  # Kept only as a convenience for manual testing from a terminal
  # (`qs-inir ipc call ...`, `qs-inir log`, etc). The real autostart path is
  # niri.nix's spawn-sh-at-startup line, which bakes the same env directly
  # into the spawn command so it doesn't depend on session-variable
  # propagation timing/reachability.
  qsWithPaths = pkgs.buildFHSEnv {
    name = "qs-inir";
    targetPkgs = pkgs: with pkgs; [
      bash coreutils findutils gnugrep gnused procps
      curl imagemagick python3 glib.dev dconf
      libsecret gnome-keyring ddcutil awww
    ];
    runScript = pkgs.writeShellScript "qs-inir-run" ''
      export QML_IMPORT_PATH="${qtImportPaths}"
      export QT_QPA_PLATFORM="wayland"
      exec ${pkgs.quickshell}/bin/qs "$@"
    '';
  };
in
{
  home.packages = with pkgs; [
    hicolor-icon-theme
    papirus-icon-theme
    quickshell
    opencode
    inirPython
    qsWithPaths
    grim
    slurp
    satty
    cliphist
    wl-clipboard
    matugen
    wlsunset
    libnotify
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugin-kvantum
    libsForQt5.qtgraphicaleffects
    kdePackages.qtstyleplugin-kvantum

    # Were missing: both are in iNiR's own documented bare-minimum
    # dependency list (wiki INSTALL page). kdialog backs some dialogs;
    # plasma-integration reads kdeglobals so Qt apps pick up Material
    # You colors. There's no nixpkgs package for darkly-bin (AUR-only,
    # the actual Qt *style* renderer) -- Qt widget chrome may look
    # slightly plain without it, but the shell itself doesn't need it
    # to run.
    kdePackages.kdialog
    kdePackages.plasma-integration

    material-symbols
    nerd-fonts.jetbrains-mono
    wireplumber
    pipewire
    swaybg

    # NOTE: verify this exists in your pinned nixpkgs before rebuilding --
    #   nix eval nixpkgs/nixos-26.05#awww.name
    # awww (recently renamed from swww, which is archived upstream) is
    # hardcoded in services/AwwwBackend.qml -- swww is NOT a drop-in
    # substitute, the shell calls the `awww` binary by name. If the eval
    # above fails, pull it from nixpkgs-unstable instead: pass pkgs-unstable
    # into this module's specialArgs and use pkgs-unstable.awww here.
    awww

    polkit_gnome
    brightnessctl
    playerctl
    fuzzel
  ];

  # Deploy the shell's own source tree as-is. No patching needed: compositor
  # selection is NOT config-driven (services/CompositorService.qml reads
  # Quickshell.env("NIRI_SOCKET") directly), so there's nothing to inject
  # here.
  xdg.configFile."quickshell/inir" = {
    source = inirSrc;
    recursive = true;
  };

  xdg.configFile."matugen" = {
  source = "${inirSrc}/dots/.config/matugen";
  recursive = true;
  };
  xdg.configFile."fuzzel" = {
    source = "${inirSrc}/dots/.config/fuzzel";
    recursive = true;
  };

  # The ONLY path the shell actually reads for user config overrides --
  # confirmed by reading modules/common/Directories.qml:
  #   shellConfig: `${configPath}/illogical-impulse`
  #   shellConfigName: "config.json"
  # NOT ~/.config/inir/config.json (that was never read). Left empty/unset
  # here deliberately -- the shell ships its own full defaults/config.json
  # (~1100 lines) and will create this file itself with sane values on
  # first run if you use the in-app Settings UI. Only add
  # xdg.configFile."illogical-impulse/config.json" yourself if you actually
  # want to force specific values declaratively; if you do, be aware (same
  # as end4-pC) that a Nix-store-backed file here means Settings-UI edits
  # won't persist across rebuilds.

  home.sessionVariables = {
    QML_IMPORT_PATH = qtImportPaths;
    QT_QPA_PLATFORM = "wayland";
  };
}
