{ self, inputs, ... }: {
  flake.nixosModules.desktopConfiguration = { pkgs, lib, ... }: {
    # import any other modules from here
    imports = [
      self.nixosModules.desktopHardware
      self.nixosModules.niri
    ];

    networking.hostName = "desktop";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    time.timeZone = "Europe/Madrid";
    system.stateVersion = "25.11";
  };
}