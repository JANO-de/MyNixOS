{ config, pkgs, lib, inputs, ... }:

{
  environment.systemPackages =
    (with pkgs; [
    direnv
    cmake
    ninja
    pkg-config
    vscodium
    neovide
    antigravity # Ide for learning
    qt6.qt5compat
    pkgs.gowall
    btop
    qbittorrent
    nodejs_22
    inputs.opencode-flake.packages.${pkgs.stdenv.hostPlatform.system}.opencode-avx

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
    cava
    mpv
    mpvScripts.mpris
    yt-dlp
    ])
    ++ lib.optionals config.modules.programs.heavy.enable (with pkgs; [
      jdk25
      zulu25
      eclipses.eclipse-java
      (pkgs.llama-cpp.override { vulkanSupport = true; })
    ]);

  environment.shellAliases.llm = "$HOME/.local/bin/llm";

  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp.override { vulkanSupport = true; };
    extraFlags = [ "--models-max" "1" ];
    
    modelsPreset = {
      "qwen3-8b" = {
        model = "/var/lib/llama-models/Qwen3-8B-Q4_K_M.gguf";
        alias = "qwen3-8b";
        ctx-size = "8192";
        fit-target = "640";
        temp = "0.6";
        top-p = "0.95";
        top-k = "20";
      };
      "qwen3-14b" = {
        model = "/var/lib/llama-models/Qwen3-14B-Q4_K_M.gguf";
        alias = "qwen3-14b";
        ctx-size = "8192";
        fit-target = "640";
        temp = "0.6";
        top-p = "0.95";
        top-k = "20";
      };
    };
  };
  programs.forge.enable = true;
}
