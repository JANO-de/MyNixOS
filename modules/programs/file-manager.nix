{ config, pkgs, ... }:

{
  # gvfs is Nautilus' backend for device enumeration/mounting (removable
  # drives, other disks, GVFS mounts). Without it Nautilus shows no other
  # disks in the sidebar and cannot mount USB devices.
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    nautilus
  ];

  # Nautilus is the default file manager on this system.
  # Dolphin stays available only inside the KDE (Plasma) session.
  xdg.mime.defaultApplications = {
    "inode/directory" = "org.gnome.Nautilus.desktop";
    "application/x-gnome-saved-search" = "org.gnome.Nautilus.desktop";
  };
}
