# Dux Search (system-wide search service for Dux Shell). On with modules.dms.enable.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.dux.search;
in
{
  options.modules.dux.search.enable = lib.mkEnableOption "Dux Search";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ inputs.dux-search.packages.${pkgs.stdenv.hostPlatform.system}.default ];
  };
}
