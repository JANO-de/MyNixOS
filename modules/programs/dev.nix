{ config, pkgs, lib, inputs, ... }:

{
  environment.systemPackages =
    (with pkgs; [
    direnv
    cmake
    ninja
    pkg-config
    vscodium
    kdePackages.kate
    neovide
    godot
    qt6.qt5compat
    pkgs.gowall
    btop
    qbittorrent
    nodejs_22
    inputs.opencode-flake.packages.${pkgs.system}.opencode-avx

    # UML Designer
    drawio

    # DAW (Music)
    ardour

    ### ----- /*/ Wayland session utilities /*/ ----- ###

    # --- Core session glue ---
    inotify-tools            # provides `inotifywait`, used by a few watchers
    xwayland-satellite       # Xwayland support under niri (non-native apps)
    swaylock
    swayidle
    wl-clipboard
    cliphist
    libnotify
    wlsunset
    xdg-user-dirs
    xdg-utils
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
    gnome-keyring
    fish                    # handy interactive shell (used by a few scripts)
    gum
    uv                       # needed to create the venv in README step 7
    bc
    ripgrep
    jq

    # --- Screenshots / OCR / screen recording ---
    grim
    slurp
    swappy
    tesseract
    wf-recorder
    ffmpeg
    pulseaudio               # provides `pactl`; needed for wf-recorder's audio mixing — NOT running the pulseaudio daemon, just the CLI

    # --- System controls the shell's widgets call ---
    brightnessctl
    ddcutil                  # external monitor brightness over DDC/CI
    upower
    blueman
    networkmanagerapplet
    pavucontrol

    # --- Fonts ---
    nerd-fonts.jetbrains-mono # nerd-font glyphs used by the eww island
    alacritty                 # terminal used by niri/config.kdl's Mod+Return bind — required for the shared config to work out of the box

    # ===========================================================================
    # OPTIONAL — features you may not use. Safe to delete any of these lines.
    # ===========================================================================
    fuzzel                    # app launcher fallback
    wtype                     # simulated keyboard input, used by a couple of automation features
    ydotool
    geoclue2                  # location for the weather widget
    fprintd                   # fingerprint unlock — only relevant if your laptop has a sensor
    libqalculate               # calculator widget backend
    translate-shell            # translate widget
    socat                      # used by a couple of IPC helper scripts
    mission-center              # system monitor GUI, launched from the dashboard
    lsp-plugins                 # audio effect plugins, only relevant if you use easyeffects/cava
    cava
    easyeffects
    mpv
    mpvScripts.mpris             # media-key/MPRIS integration for the YouTube Music widget
    yt-dlp
    ])
    # Heavy Java/IDE toolchain — gated by modules.programs.heavy.enable so lean
    # tablets (Surface: 4GB RAM, 128GB disk) skip the biggest store hogs:
    # Android Studio, IntelliJ, Eclipse, extra JDKs and every transitive dep
    # (jetbrains jdk/jcef alone is ~1.3GB).
    ++ lib.optionals config.modules.programs.heavy.enable (with pkgs; [
      jdk25
      zulu25
      android-studio
      eclipses.eclipse-java
      jetbrains.idea
    ]);
}
