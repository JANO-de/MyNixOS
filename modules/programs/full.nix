{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.modules.programs;
  system = pkgs.stdenv.hostPlatform.system;
  full = cfg.profile == "full";
  llama = pkgs.llama-cpp.override { vulkanSupport = true; };
in
lib.mkIf full {
  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages.${system}.default
    vesktop
    bazaar
    inputs.claude-desktop.packages.${system}.claude-desktop-with-fhs
    inputs.opencode-flake.packages.${system}.opencode-avx
    proton-vpn

    vscodium
    eclipses.eclipse-java
    jetbrains.idea
    netbeans

    jdk25 maven gradle
    gcc gdb clang-tools cmake ninja pkg-config
    python3 ruff uv
    nodejs_22
    nixd nixfmt direnv

    llama

    libreoffice-qt
    inputs.classwork.packages.${system}.default

    nautilus
    yazi chafa ffmpegthumbnailer poppler-utils p7zip
  ];

  services.gvfs.enable = true;
  xdg.mime.defaultApplications = {
    "inode/directory" = "org.gnome.Nautilus.desktop";
    "application/x-gnome-saved-search" = "org.gnome.Nautilus.desktop";
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [ stdenv.cc.cc.lib zlib openssl ];
  };

  programs.forge.enable = true;
  environment.shellAliases.llm = "$HOME/.local/bin/llm";

  services.llama-cpp = {
    enable = true;
    package = llama;
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
}
