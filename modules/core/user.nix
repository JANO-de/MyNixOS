{ config, pkgs, ... }:

{
  users.users.jano = {
    isNormalUser = true;
    description = "jano";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" ];
  };
}
