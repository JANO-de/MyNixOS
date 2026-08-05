{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    dissent
    zapzap
  ];
}
