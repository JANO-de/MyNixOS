# Terminal + CLI essentials. Small and GUI-free, so the lean (Surface) set
# imports it too. `atuin`/`zoxide` need a shell-rc init line to become
# automatic; the binaries are installed here so that choice stays in the rc.
{ config, pkgs, lib, ... }:

{
  environment.systemPackages =
    (with pkgs; [
      neovim
      git
      wget
      curl
      alacritty
      starship
      eza
      bat
      ripgrep
      fd
      procs
      zoxide
      z-lua
      fastfetch
    ])
    ++ lib.optionals config.modules.programs.qol.enable (with pkgs; [
      atuin
      btop
      delta
      dust
      fzf
      ncdu
      tmux
      yq-go
    ]);
}
