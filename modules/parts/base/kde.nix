{ self, inputs, ... }: {
  flake.nixosModules.kde = { pkgs, lib, ... }: {
    services = {
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        # Use lib.mkDefault to avoid the "multiple definitions" error
        package = lib.mkDefault pkgs.kdePackages.sddm; 
      };
      desktopManager.plasma6.enable = true;
    };

    services.displayManager.sessionPackages = [ pkgs.kdePackages.plasma-desktop ];

    environment.systemPackages = with pkgs; [
    # KDE Utilities
    kdePackages.kcalc # Calculator
    kdePackages.kcharselect # Character map
    kdePackages.kclock # Clock app
    kdePackages.kcolorchooser # Color picker
    kdePackages.kolourpaint # Simple paint program
    kdePackages.ksystemlog # System log viewer
    kdePackages.sddm-kcm # SDDM configuration module
    kdiff3 # File/directory comparison tool
    
    # Hardware/System Utilities (Optional)
    kdePackages.isoimagewriter # Write hybrid ISOs to USB
    kdePackages.partitionmanager # Disk and partition management
    hardinfo2 # System benchmarks and hardware info
    wayland-utils # Wayland diagnostic tools
    wl-clipboard # Wayland copy/paste support
    vlc # Media player
    ];
  };
}