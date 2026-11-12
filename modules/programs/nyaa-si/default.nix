# nyaa-si program module (programs.nyaa-si.enable): nyaa.si TUI explorer + BitTorrent client.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.nyaa-si;
in
{
  options.programs.nyaa-si = {
    enable = lib.mkEnableOption "nyaa-si, nyaa.si TUI explorer and BitTorrent client";
    package = lib.mkPackageOption pkgs "nyaa-si" { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
