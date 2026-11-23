# Printing: CUPS plus Avahi so network printers (driverless IPP) are discovered.
_: {
  flake.nixosModules.services-printing =
    { config, lib, ... }:

    {
      config = lib.mkIf config.modules.services.enable {
        services.printing.enable = true;
        services.printing.browsed.enable = false;
        services.avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };

        hardware.printers = {
          ensurePrinters = [
            {
              name = "Brother_HL-L3220CW";
              description = "Brother HL-L3220CW";
              deviceUri = "ipp://BRW4845E63B0175.local:631/ipp/print";
              model = "everywhere";
              ppdOptions.PageSize = "A4";
            }
          ];
          ensureDefaultPrinter = "Brother_HL-L3220CW";
        };
      };
    };
}
