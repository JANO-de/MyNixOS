# Desktop PC: AMD + NVIDIA (GTX 1060). mango + dynisland.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core.nix
    ../../modules/hardware.nix
    ../../modules/services.nix
    ../../modules/programs.nix
    ../../modules/desktop
    ../../modules/extras/matrix.nix
  ];

  networking.hostName = "desktop";

  # Without this, custom substituters (e.g. from a flake's nixConfig) are
  # silently ignored for this user's builds, and the daemon just rebuilds from
  # source. Also lets the Surface receive unsigned paths pushed from here.
  nix.settings.trusted-users = [ "root" "jano" ];

  # Internal data drives (ext4). "nofail" keeps boot snappy if one is missing,
  # "noatime" avoids needless write traffic.
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
  modules.hardware.elementsDrive.enable = true;

  # The Surface acts as an extra monitor via this sunshine server + moonlight.
  # Capture runs on the NVIDIA/Intel hybrid GPU under Wayland: if streaming is
  # flaky, test the KMS backend.
  modules.services.sunshine.enable = true;

  # Deskflow: this machine joins the laptop's keyboard/mouse server.
  modules.programs.deskflow = {
    role = "client";
    serverAddress = "laptop";
  };

  # Optional: pin a fractional scale on the 4K monitor (find names with
  # `mmsg get all-monitors`), then rebuild:
  # modules.desktop.mango.monitorRules = [
  #   "name:^HDMI-A-1$,width:3840,height:2160,refresh:60,x:0,y:0,scale:1.5"
  # ];

  system.stateVersion = "26.05";
}
