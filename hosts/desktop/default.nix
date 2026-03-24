{ self, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix
    "${self}/modules/core"
  ];

  networking.hostName = "desktop";
  # Laptop specific tweaks (like power management) go here
}
