# Bundle: every gaming module. Members are set with mkDefault, so a host can still turn one off.
{ config, lib, ... }:
{
  options.modules.gaming.all = lib.mkEnableOption "every gaming module (steam, gamemode)";

  config = lib.mkIf config.modules.gaming.all {
    modules.gaming.steam = lib.mkDefault true;
    modules.gaming.gamemode = lib.mkDefault true;
  };
}
