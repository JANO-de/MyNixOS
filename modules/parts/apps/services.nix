{ self, inputs, ... }: {
  flake.nixosModules.services = { pkgs, lib, config, ... }: 
  {
    services = {
      dunst.enable = true;
      flatpak.enable = true;
      gvfs.enable = true;
    };

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      ensureDatabases = [ "bookmarket" ];
      ensureUsers = [
        {
          name = "bookmarket";
          ensureDBOwnership = true;
        }
      ];
      authentication = pkgs.lib.mkOverride 10 ''
        # TYPE  DATABASE        USER            ADDRESS         METHOD
        local   all             all                             trust
        host    all             all             127.0.0.1/32    scram-sha-256
        host    all             all             ::1/128         scram-sha-256
      '';
    };

    services.udev.extraRules = ''
      # MediaTek BROM (The KingKong 9 ID)
      SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", ATTR{idProduct}=="0003", MODE="0666", GROUP="adbusers"
      # MediaTek Preloader
      SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", ATTR{idProduct}=="2000", MODE="0666", GROUP="adbusers"
      
      # Blacklist modem-manager from touching the device
      ATTRS{idVendor}=="0e8d", ATTRS{idProduct}=="0003", ENV{ID_MM_DEVICE_IGNORE}="1"
    '';
  };
}