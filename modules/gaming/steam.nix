# Steam. Empty until the owner sends the package list (ASK-7).
{ config, lib, ... }:
let
  cfg = config.modules.gaming.steam;
in
{
  options.modules.gaming.steam = lib.mkEnableOption "Steam";

  config = lib.mkIf cfg { };
}
