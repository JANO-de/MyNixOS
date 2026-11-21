# Daily restic backup of service databases/configs (NOT the media itself).
# Repository lives on /mnt/ssd, a different disk than the btrfs pool.
{ ... }:
{
  services.restic.backups.server = {
    initialize = true;
    repository = "/mnt/ssd/restic";
    passwordFile = "/root/restic-password";
    paths = [
      "/mnt/storage/jellyfin"
      "/mnt/storage/tracker"
      "/var/lib/navidrome"
    ];
    exclude = [ "/mnt/storage/jellyfin/cache" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
  };
}
