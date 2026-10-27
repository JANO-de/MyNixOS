# Lean profile: CLI essentials + zathura + moonlight + deskflow (all hosts).
{ config, lib, pkgs, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  environment.systemPackages = with pkgs; [
    neovim git wget curl jq
    alacritty starship fastfetch
    eza bat ripgrep fd procs zoxide z-lua
    atuin btop delta dust fzf ncdu tmux yq-go
    inputs.forge.packages.${system}.forge
    appimage-run

    deskflow
    moonlight-qt

    (zathura.override {
      plugins = with zathuraPkgs; [ zathura_pdf_mupdf zathura_pdf_poppler ];
    })
  ];
}
