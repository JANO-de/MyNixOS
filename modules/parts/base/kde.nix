{ self, inputs, ... }: {
  flake.nixosModules.kde = { pkgs, ... }: {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true; # Crucial para Niri/Plasma Wayland
      theme = "sugar-candy"; # O el que prefieras
    };
    services.desktopManager.plasma6.enable = true;

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