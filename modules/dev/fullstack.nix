# Full-stack development tools. Empty until the owner sends the package list (ASK-7).
{ config, lib, ... }:
let
  cfg = config.modules.dev.fullstack;
in
{
  options.modules.dev.fullstack = lib.mkEnableOption "full-stack development tools";

  config = lib.mkIf cfg { };
}
