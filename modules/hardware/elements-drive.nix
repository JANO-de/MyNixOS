# External NTFS drive "Elements" (Seagate), shared by desktop and laptop.
# ntfs-3g (FUSE) is safe for read/write; "nofail" keeps boot from blocking when
# the drive is unplugged (then just open /mnt/Elements to access it).
{ pkgs, ... }:

{
  fileSystems."/mnt/Elements" = {
    device = "/dev/disk/by-uuid/D6B6960AB695EB6F";
    fsType = "ntfs-3g";
    options = [ "nofail" "uid=1000" "gid=100" "umask=000" ];
  };

  # provides the mount.ntfs-3g helper used by the mount above
  environment.systemPackages = [ pkgs.ntfs3g ];
}
