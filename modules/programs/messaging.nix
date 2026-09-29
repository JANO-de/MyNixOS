{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    dissent
    legcord
    zapzap
    simplex-chat-desktop
  ];
}
