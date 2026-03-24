{ ... }: {
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix
    ../../modules/core # Any shared system modules
  ];

  networking.hostName = "desktop";
  # Laptop specific tweaks (like power management) go here
}
