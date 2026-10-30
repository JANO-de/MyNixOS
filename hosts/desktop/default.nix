# Desktop PC: AMD + NVIDIA (GTX 1060). Hyprland + ii (variant p3drovfx).
# Boot entry "vynx" = same host with ii-vynx.
{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
    ../../modules/hardware
    ../../modules/services
    ../../modules/programs
    ../../modules/programs/orchard.nix
    ../../modules/desktop
    ../../hosts/desktop/matrix.nix
  ];

  networking.hostName = "desktop";

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

  modules.desktop.session = "hyprland";
  modules.desktop.shell = "ii";
  modules.desktop.ii.enable = true;
  modules.desktop.drmDevices = "/dev/dri/dgpu";
  modules.desktop.dotfiles.enable = true;
  # Legacy flat layout; delete after running scripts/migrate-dotfiles-per-host.sh desktop.
  modules.desktop.dotfiles.dir = "/home/jano/Proyectos/MyNixOS/dotfiles";

  # Legacy: only read by the mango session (remove together with mango).
  modules.desktop.mango.monitorRules = [
    "name:^HDMI-A-1,width:1080,height:1920,refresh:60,rr:1"
    "name:^HDMI-A-2,width:1080,height:1920,refresh:60,rr:0"
  ];

  # Boot entry "vynx": ii-vynx instead of ii-p3drovfx, with its own dotfiles folder.
  # mkForce: the base sets the legacy flat dir above. See docs/ii.md.
  specialisation.vynx.configuration = {
    modules.desktop.ii.variant = "vynx";
    modules.desktop.dotfiles.dir = lib.mkForce "/home/jano/Proyectos/MyNixOS/dotfiles/desktop-vynx";
  };

  system.stateVersion = "26.05";
}
