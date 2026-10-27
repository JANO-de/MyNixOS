# nixscout program module (programs.nixscout.enable).
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.nixscout;
in
{
  options.programs.nixscout = {
    enable = lib.mkEnableOption "nixscout Nix browser";
    package = lib.mkPackageOption pkgs "nixscout" { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
