# SSH server.
{ config, lib, ... }:

{
  config = lib.mkIf config.modules.services.enable {
    services.openssh.enable = true;
  };
}
