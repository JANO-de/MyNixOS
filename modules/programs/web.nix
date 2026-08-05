{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (librewolf.override { nativeMessagingHosts = [ pkgs.firefoxpwa ]; })
    firefoxpwa
  ];
}
