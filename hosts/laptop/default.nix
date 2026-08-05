{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
    ../../modules/hardware
    ../../modules/services
    ../../modules/desktop
    ../../modules/programs
  ];

  networking.hostName = "laptop";

  time.timeZone = "Europe/Madrid";

  i18n.defaultLocale = "es_ES.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_ES.UTF-8";
    LC_IDENTIFICATION = "es_ES.UTF-8";
    LC_MEASUREMENT = "es_ES.UTF-8";
    LC_MONETARY = "es_ES.UTF-8";
    LC_NAME = "es_ES.UTF-8";
    LC_NUMERIC = "es_ES.UTF-8";
    LC_PAPER = "es_ES.UTF-8";
    LC_TELEPHONE = "es_ES.UTF-8";
    LC_TIME = "es_ES.UTF-8";
  };

  console.keyMap = "es";

  # Home Manager: per-user declarative configuration lives in ../../modules/home
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users.jano = import ../../modules/home/default.nix;
  };

  system.stateVersion = "26.05";
}
