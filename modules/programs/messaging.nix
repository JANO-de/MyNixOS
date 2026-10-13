{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    dissent
    vesktop
    zapzap
    simplex-chat-desktop
  ];
}
