{ ... }: {
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix
  ];

  networking.hostName = "laptop";
  # Laptop specific tweaks (like power management) go here
}
