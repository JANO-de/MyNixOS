# Monthly btrfs scrub of the storage pool.
# Data is "single": scrub detects bad data files but cannot repair them.
_: {
  flake.nixosModules.services-scrub = _: {
    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/mnt/storage" ];
    };
  };
}
