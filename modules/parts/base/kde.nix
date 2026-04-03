{ self, inputs, ... }: {
  flake.nixosModules.kde = { pkgs, lib, ... }: {
    services.desktopManager.plasma6.enable = true;
    services.displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
    };

    environment.systemPackages = with pkgs; [
      # KDE Utilities
      kdePackages.kcalc
      kdePackages.kcharselect
      kdePackages.kclock
      kdePackages.kcolorchooser
      kdePackages.kolourpaint
      kdePackages.ksystemlog
      kdePackages.sddm-kcm
      kdiff3
      
      # Hardware/System Utilities
      kdePackages.isoimagewriter
      kdePackages.partitionmanager
      hardinfo2
      wayland-utils
      wl-clipboard
      vlc
    ];
  };
}
