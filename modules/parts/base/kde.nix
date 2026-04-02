{ self, inputs, ... }: {
  flake.nixosModules.kde = { pkgs, lib, ... }: {
    
    services.xserver.enable = true;
    services.xserver.displayManager.lightdm = {
      enable = true;

      # Setting gtk as the greeter
      greeters.gtk.enable = true;

      # Example of having background as a particular color
      background = "#6b321b";

      # Example of the default image background (must be an absolute path)
      #background = pkgs.nixos-artwork.wallpapers.simple-dark-gray-bottom.gnomeFilePath;

    };
    
    # services.displayManager.sessionPackages = [ pkgs.kdePackages.plasma-desktop ];

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