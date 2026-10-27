{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.orchard;
in
{
  options.programs.orchard = {
    enable = lib.mkEnableOption "Orchard music client";
    package = lib.mkPackageOption pkgs "orchard" { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
