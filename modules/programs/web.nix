{ config, pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    librewolf
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
  services.simpmusic.enable = true;
  services.xdg.menu.Items.simpmusic = {
    type = "Application";
    name = "SimpMusic";
    exec = "simpmusic";
    categories = [ "Audio" "AudioVideo" ];
  };
}
