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

  qsWithPaths = pkgs.writeShellScriptBin "qs-inir" ''
    export QML_IMPORT_PATH="${qtImportPaths}"
    export QT_QPA_PLATFORM="wayland"
    exec ${pkgs.quickshell}/bin/qs "$@"
  '';

  inirPatched = pkgs.runCommand "inir-patched" { } ''
    cp -r ${inirSrc} $out
    chmod -R u+w $out
    mkdir -p $out/config
    cat > $out/config/default.json <<'INIREOF'
    {
      "general": {
        "compositor": "niri",
        "panelFamily": "ii",
        "style": "Material",
        "language": "auto"
      }
    }
    INIREOF
  '';
in
{
  home.packages = with pkgs; [
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
    material-symbols
    nerd-fonts.jetbrains-mono
    wireplumber
    pipewire
    swaybg
    awww
    polkit_gnome
    brightnessctl
    playerctl
    fuzzel
  ];

  xdg.configFile."quickshell/inir".source = inirPatched;
  xdg.configFile."quickshell/inir".recursive = true;

  xdg.configFile."inir/config.json".text = lib.toJSON {
    general = {
      compositor = "niri";
      panelFamily = "ii";
      style = "Material";
      language = "auto";
    };
  };

  home.sessionVariables = {
    QML_IMPORT_PATH = qtImportPaths;
    QT_QPA_PLATFORM = "wayland";
    INIR_COMPOSITOR = "niri";
  };
}