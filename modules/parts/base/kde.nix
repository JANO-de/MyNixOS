{ self, inputs, ... }: {
  flake.nixosModules.kde = { pkgs, lib, ... }: {
    services.desktopManager.plasma6.enable = true;
    services.displayManager = {
      sddm = {
        enable = true;
        package = pkgs.kdePackages.sddm; # Fuerza la versión compatible con Plasma 6
        wayland.enable = true; # En tarjetas modernas, SDDM-Wayland suele ser más estable que X11
      };
      gdm = {
        enable = false;
      };
    };
    services.xserver.displayManager.gdm.enable = false;
    services.xserver.displayManager.gdm.wayland = false;

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
