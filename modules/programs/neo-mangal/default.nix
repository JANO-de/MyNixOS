# neo-mangal program module (programs.neo-mangal.enable): manga TUI downloader + KCC converter.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.neo-mangal;
in
{
  options.programs.neo-mangal = {
    enable = lib.mkEnableOption "neo-mangal, manga TUI downloader";
    package = lib.mkPackageOption pkgs "neo-mangal" { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
