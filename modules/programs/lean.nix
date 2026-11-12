# Lean profile: CLI essentials + ffmpeg/yt-dlp + zathura + moonlight + deskflow (all hosts).
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  cfg = config.modules.programs;
in
lib.mkIf cfg.enable {
  environment.systemPackages = with pkgs; [
    neovim
    gcc
    tree-sitter
    nodejs
    nil
    lua-language-server
    nixfmt
    stylua
    vtsls
    tailwindcss-language-server
    vscode-langservers-extracted
    yaml-language-server
    taplo
    marksman
    prettierd
    bash-language-server
    shellcheck
    shfmt
    statix
    deadnix
    lazygit
    git
    wget
    curl
    jq
    alacritty
    starship
    fastfetch
    eza
    bat
    ripgrep
    fd
    procs
    zoxide
    z-lua
    atuin
    btop
    delta
    dust
    fzf
    ncdu
    tmux
    yq-go
    inputs.forge.packages.${system}.forge
    appimage-run
    ffmpeg
    yt-dlp

    deskflow
    moonlight-qt

    (zathura.override {
      plugins = with zathuraPkgs; [
        zathura_pdf_mupdf
        zathura_pdf_poppler
      ];
    })
  ];
}
