# SSH server.
_: {
  flake.nixosModules.services-ssh =
    { config, lib, ... }:

    {
      config = lib.mkIf config.modules.services.enable {
        services.openssh.enable = true;
      };
    };
}
