# Dux GOP (system monitor). On with modules.dms.enable.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.dux.gop;
in
{
  options.modules.dux.gop.enable = lib.mkEnableOption "Dux GOP";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ inputs.dux-gop.packages.${pkgs.stdenv.hostPlatform.system}.default ];
  };
}
