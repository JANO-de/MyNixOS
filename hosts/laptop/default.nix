{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
    ../../modules/hardware
    ../../modules/hardware/elements-drive.nix
    ../../modules/services
    ../../modules/desktop
    ../../modules/programs # full set
  ];

  networking.hostName = "laptop";

  # XAMPP workbench (/opt/lampp) lives only here.
  modules.services.xampp.enable = true;

  # The Surface acts as an extra monitor via this sunshine server + moonlight
  # on the tablet (KMS/pipewire capture under niri).
  modules.services.sunshine.enable = true;

  # Deskflow keyboard/mouse sharing: pick one.
  #   modules.programs.deskflow.role = "server";
  #   modules.programs.deskflow.role = "client"; modules.programs.deskflow.serverAddress = "desktop";

  system.stateVersion = "26.05";
}
