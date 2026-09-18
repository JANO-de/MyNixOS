{ config, pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    librewolf
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
