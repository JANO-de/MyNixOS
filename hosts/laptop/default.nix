{ ... }: {
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix
    ../../modules/core # Any shared system modules
  ];

  networking.hostName = "laptop";
  # Laptop specific tweaks (like power management) go here
}
