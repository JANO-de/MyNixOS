# Dux Calendar. On with modules.dms.enable.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.dux.calendar;
in
{
  options.modules.dux.calendar.enable = lib.mkEnableOption "Dux Calendar";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ inputs.dux-calendar.packages.${pkgs.stdenv.hostPlatform.system}.default ];
  };
}
