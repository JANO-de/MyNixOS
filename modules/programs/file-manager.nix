{ config, pkgs, ... }:

{
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
