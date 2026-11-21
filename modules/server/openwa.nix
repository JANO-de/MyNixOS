# Docker for OpenWA (WhatsApp API gateway). Compose app lives in ~/openwa.
{ config, lib, ... }:
let
  cfg = config.modules.services.openwa;
in
{
  options.modules.services.openwa.enable = lib.mkEnableOption "Docker for OpenWA";

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;
    users.users.jano.extraGroups = [ "docker" ];
  };
}
