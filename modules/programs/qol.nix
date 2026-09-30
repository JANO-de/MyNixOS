{ config, pkgs, lib, ... }:

# QoL CLI toolkit — tiny closures, terminal-first: sysmon, history search,
# fuzzy find, faster ls/cat/diff, tmux and a YAML swiss-army knife.
{
  environment.systemPackages = lib.optionals config.modules.programs.qol.enable (with pkgs; [
    btop
    atuin
    zoxide
    fzf
    eza
    bat
    delta
    tmux
    yq
  ]);
}