# Disk layout by label (no hardware-configuration.nix on purpose, so this
# unit's UUIDs never get committed). Shared with surface-bootstrap:
#   mkfs.fat -F32 -n NIXBOOT <p1>; mkfs.ext4 -L NIXROOT <p2>
# i.e. 512MB FAT32 EFI System Partition, rest ext4.
{ ... }:

{
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "ext4";
  };
}
