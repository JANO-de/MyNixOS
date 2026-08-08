{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    obsidian
    onlyoffice-desktopeditors
  ];
}
