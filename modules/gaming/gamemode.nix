# GameMode. Empty until the owner sends the package list (ASK-7).
{ config, lib, ... }:
let
  cfg = config.modules.gaming.gamemode;
in
{
  options.modules.gaming.gamemode = lib.mkEnableOption "GameMode";

  config = lib.mkIf cfg { };
}
