{ config, pkgs, lib, ... }:

<<<<<<< HEAD
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
=======
# Small terminal quality-of-life: better listing/search/history than the stock
# coreutils set, lightweight process and disk inspection, and JSON/yaml
# handling. Every one of these is a few MB and none of them needs a GUI, so
# they are safe on the low-RAM tablet.
#
# `atuin` and `zoxide` only become automatic with a line in the shell rc
# (`eval "$(atuin init bash)"`, `eval "$(zoxide init bash)"`); the binaries are
# installed here so the choice stays with the shell profile.
{
  environment.systemPackages = lib.optionals config.modules.programs.qol.enable (
    with pkgs; [
      atuin
      bat
      btop
      delta
      dust
      eza
      fzf
      ncdu
      tmux
      disktree
      yq-go
      zoxide
    ]
  );
}
>>>>>>> bb95542e9e6c1400db55d062a5cf70c50aedc643
