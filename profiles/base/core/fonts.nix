# System fonts.
{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    dm-mono
    jetbrains-mono
    material-symbols
  ];
}
