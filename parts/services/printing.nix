# Printing.
_: {
  flake.nixosModules.services-printing =
    { config, lib, ... }:

    {
      config = lib.mkIf config.modules.services.enable {
        services.printing.enable = true;
      };
    };
}
