{ config, pkgs, lib, inputs, ... }:
let
  # Keeps only the extensions that exist in this nixpkgs, so a wrong/missing name can't break the build.
  pick = paths: lib.concatMap (p:
    let v = lib.attrByPath (lib.splitString "." p) null pkgs.vscode-extensions;
    in lib.optional (v != null) v) paths;
in
{
  environment.systemPackages =
    (with pkgs; [
    direnv
    cmake
    ninja
    pkg-config
    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions = pick [
        # AI + theme
        "continue.continue" "enkia.tokyo-night"
        # Java
        "redhat.java" "vscjava.vscode-java-debug" "vscjava.vscode-java-test"
        "vscjava.vscode-maven" "vscjava.vscode-gradle" "vscjava.vscode-java-dependency"
        # Python
        "ms-python.python" "ms-python.debugpy" "charliermarsh.ruff"
        # C/C++
        "llvm-vs-code-extensions.vscode-clangd" "vadimcn.vscode-lldb"
        "ms-vscode.cmake-tools" "twxs.cmake"
        # Web / data
        "esbenp.prettier-vscode" "dbaeumer.vscode-eslint" "ritwickdey.liveserver"
        "formulahendry.auto-rename-tag" "christian-kohler.path-intellisense"
        "bradlc.vscode-tailwindcss" "mechatroner.rainbow-csv"
        "redhat.vscode-xml" "redhat.vscode-yaml" "tamasfe.even-better-toml"
        # SQL / DB
        "mtxr.sqltools"
        # Nix
        "jnoortheen.nix-ide" "mkhl.direnv"
        # Git / quality of life
        "eamodio.gitlens" "mhutchie.git-graph" "usernamehw.errorlens"
        "editorconfig.editorconfig" "gruntfuggly.todo-tree"
        "streetsidesoftware.code-spell-checker" "yzhang.markdown-all-in-one"
        "pkief.material-icon-theme" "ms-ceintl.vscode-language-pack-es"
      ];
    })
    # Tools the extensions call (language servers, compilers, formatters)
    nixd nixfmt clang-tools gcc gdb python3 ruff maven gradle
    neovide
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
