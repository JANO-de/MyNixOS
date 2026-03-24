{ ... }: {
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix
  ];

  networking.hostName = "desktop";
  # Laptop specific tweaks (like power management) go here
}
