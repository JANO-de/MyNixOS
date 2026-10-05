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

  networking.hostName = "desktop";

  # Freshly formatted internal data drives (ext4). "nofail" keeps boot snappy
  # even if a drive is missing, "noatime" avoids needless write traffic.
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/f6a19317-f36e-4a3f-8934-423b2e3d8ed4";
    fsType = "ext4";
    options = [ "nofail" "noatime" ];
  };

  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-uuid/949f3a95-eae7-4068-a57a-ff0d695142e1";
    fsType = "ext4";
    options = [ "nofail" "noatime" ];
  };

  # The Surface acts as an extra monitor via this sunshine server + moonlight
  # on the tablet. NB: capture on this host runs on the NVIDIA/Intel hybrid
  # GPU under Wayland, so test the KMS backend if streaming is flaky.
  modules.services.sunshine.enable = true;

  # Android-in-a-container alongside the desktop session (Waydroid).
  modules.services.waydroid.enable = true;

  # SDDM defaults `defaultSession` to plasma; left alone the greeter would start
  # Plasma instead of niri and login would look like it failed (blank screen).
  services.displayManager.defaultSession = "niri";

  # Deskflow keyboard/mouse sharing: this machine joins the laptop's server.
  modules.programs.deskflow.role = "client";
  modules.programs.heavy.enable = true;
  modules.programs.deskflow.serverAddress = "laptop";

  system.stateVersion = "26.05";
}
