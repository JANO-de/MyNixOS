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
    inotify-tools
    xwayland-satellite
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
    fish
    gum
    uv
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
    pulseaudio

    # --- System controls the shell's widgets call ---
    brightnessctl
    ddcutil
    upower
    blueman
    networkmanagerapplet
    pavucontrol

    # --- Fonts ---
    nerd-fonts.jetbrains-mono
    alacritty

    # ===========================================================================
    # OPTIONAL
    # ===========================================================================
    fuzzel
    wtype
    ydotool
    geoclue2
    fprintd
    libqalculate
    translate-shell
    socat
    mission-center
    lsp-plugins
    cava
    easyeffects
    mpv
    mpvScripts.mpris
    yt-dlp
    ])
    ++ lib.optionals config.modules.programs.heavy.enable (with pkgs; [
      jdk25
      zulu25
      android-studio
      eclipses.eclipse-java
      pkgs.llama-cpp.override { cudaSupport = true; }
      jetbrains.idea
    ]);

  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp.override { cudaSupport = true; };
    
    modelsPreset = {
      "mistral-7b" = {
        hf-repo = "TheBloke/Mistral-7B-Instruct-v0.2-GGUF";
        hf-file = "Mistral-7B-Instruct-v0.2.Q4_K_M.gguf";
        alias = "mistral-7b";
        temp = "0.7";
        top-p = "0.95";
        top-k = "40";
      };
    };
  };
}