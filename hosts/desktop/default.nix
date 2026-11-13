# Desktop PC: AMD + NVIDIA (GTX 1060). niri + Aureli.
{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  networking.hostName = "desktop";

  modules.hardware.enable = true;
  modules.hardware.nvidia.enable = true;
  modules.hardware.openrgb.enable = true;
  modules.services.enable = true;
  modules.services.qmk.enable = true;
  modules.services.virtualbox.enable = true;
  modules.services.tailscale.enable = true;
  modules.theme.enable = true;
  modules.programs.enable = true;
  modules.desktop.enable = true;
  modules.desktop.compositor = "niri";
  modules.desktop.shell = "noctalia";
  services.upower.enable = true; # battery service

  # Without this, custom substituters (e.g. from a flake's nixConfig) are
  # silently ignored for this user's builds, and the daemon just rebuilds from
  # source. Also lets the Surface receive unsigned paths pushed from here.
  nix.settings.trusted-users = [
    "root"
    "jano"
  ];

  # Internal data drives (ext4). "nofail" keeps boot snappy if one is missing,
  # "noatime" avoids needless write traffic.
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/f6a19317-f36e-4a3f-8934-423b2e3d8ed4";
    fsType = "ext4";
    options = [
      "nofail"
      "noatime"
    ];
  };
  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-uuid/949f3a95-eae7-4068-a57a-ff0d695142e1";
    fsType = "ext4";
    options = [
      "nofail"
      "noatime"
    ];
  };

  # The Surface acts as an extra monitor via this sunshine server + moonlight.
  # Capture runs on the NVIDIA/Intel hybrid GPU under Wayland: if streaming is
  # flaky, test the KMS backend.
  modules.services.sunshine.enable = true;

  # Deskflow: this machine joins the laptop's keyboard/mouse server.
  modules.programs.deskflow = {
    role = "client";
    serverAddress = "laptop";
  };

  programs.orchard.enable = true;
  programs.niXscout.enable = true;
  programs.nyaa-si.enable = true;
  programs.neo-mangal.enable = true;
  programs.vid-dl.enable = true;

  modules.desktop.dotfiles.enable = true;
  modules.services.odysseus.enable = false;
  modules.services.mediaTracker.enable = true;
  modules.services.jellyfin.enable = true;
  modules.services.homepage.enable = true;
  modules.services.mediaStack.enable = true;

  system.stateVersion = "26.05";
}
