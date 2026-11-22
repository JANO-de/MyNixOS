# GameMode.
{ config, lib, ... }:
let
  cfg = config.modules.gaming.gamemode;
in
{
  options.modules.gaming.gamemode = lib.mkEnableOption "GameMode";

  config = lib.mkIf cfg {
    programs.gamemode.enable = true;
    users.users.jano.extraGroups = [ "gamemode" ];
  };
}
