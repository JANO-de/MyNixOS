# Java development tools. Empty until the owner sends the package list (ASK-7).
{ config, lib, ... }:
let
  cfg = config.modules.dev.java;
in
{
  options.modules.dev.java = lib.mkEnableOption "Java development tools";

  config = lib.mkIf cfg { };
}
