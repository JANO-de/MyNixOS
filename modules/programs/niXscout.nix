# niXscout program module (programs.niXscout.enable).
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.niXscout;
in
{
  options.programs.niXscout = {
    enable = lib.mkEnableOption "niXscout Nix browser";
    package = lib.mkPackageOption pkgs "niXscout" { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
