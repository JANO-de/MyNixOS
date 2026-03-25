{ self, inputs, ... }: {
  flake.nixosModules.desktopConfiguration = { pkgs, lib, ... }: {
    # import any other modules from here
    imports = [
      self.nixosModules.desktopHardware
      self.nixosModules.niri
    ];

    networking.hostName = "laptop";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    
    users.users.jano = {
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" "video" ];
    };

    # Graphics and Sound (from your original file) [cite: 14, 15]
    services.pipewire = {
      enable = true;
      alsa.enable = true;
     pulse.enable = true;
    };

    # Standard Locale/Time settings from your original file [cite: 7, 8]
    time.timeZone = "Europe/Madrid";
    system.stateVersion = "25.11";
  };
}