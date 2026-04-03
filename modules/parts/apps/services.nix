{ self, inputs, ... }: {
  flake.nixosModules.services = { pkgs, lib, config, ... }: 
  {
    services = {
      dunst.enable = true;
      flatpak.enable = true;
      gvfs.enable = true;
    };

    systemd.user.services.my-ags = {
      description = "AGS Shell (Noctalia-like)";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${self.packages.${pkgs.system}.myAgs}/bin/my-ags-shell";
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