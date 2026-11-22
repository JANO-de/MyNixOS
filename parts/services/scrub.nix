# Monthly btrfs scrub of the storage pool.
# Data is "single": scrub detects bad data files but cannot repair them.
{ ... }:
{
  flake.nixosModules.services-scrub =
    { ... }:
    {
      services.btrfs.autoScrub = {
        enable = true;
        interval = "monthly";
        fileSystems = [ "/mnt/storage" ];
      };
    };
}
