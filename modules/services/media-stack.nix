# Media automation: Prowlarr (indexers) -> Sonarr/Radarr (library) -> qBittorrent (downloads)
# -> /mnt/storage/media (Jellyfin), plus Jellyseerr (request page).
# Web UIs are only opened on the tailscale0 interface.
{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.services.mediaStack;
  ports = {
    sonarr = 8989;
    radarr = 7878;
    prowlarr = 9696;
    jellyseerr = 5055;
    qbittorrent = 8112; # not 8080: Homepage uses it
  };
in
{
  options.modules.services.mediaStack = {
    enable = lib.mkEnableOption "Sonarr, Radarr, Prowlarr, qBittorrent and Jellyseerr";

    mediaDir = lib.mkOption {
      type = lib.types.path;
      default = config.modules.services.jellyfin.mediaDir;
      description = "Media library root (Jellyfin reads it, Sonarr/Radarr write it).";
    };

    downloadDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/storage/downloads";
      description = "Where qBittorrent downloads (same disk as mediaDir so imports are instant hardlinks/moves).";
    };

    qbittorrent.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run qBittorrent as the download client (turn off if you bring your own).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Shared "users" group so jano, Jellyfin and the *arr apps can all read/write the library.
    services.sonarr = {
      enable = true;
      group = "users";
    };
    services.radarr = {
      enable = true;
      group = "users";
    };
    services.prowlarr.enable = true;
    services.seerr.enable = true; # renamed from services.jellyseerr

    services.qbittorrent = lib.mkIf cfg.qbittorrent.enable {
      enable = true;
      group = "users";
      webuiPort = ports.qbittorrent;
      serverConfig.Preferences.WebUI.LocalHostAuth = false;
    };

    # Group-writable files so jano can still manage what the apps create.
    systemd.services.sonarr.serviceConfig.UMask = lib.mkForce "0002";
    systemd.services.radarr.serviceConfig.UMask = lib.mkForce "0002";
    systemd.services.qbittorrent.serviceConfig.UMask = lib.mkIf cfg.qbittorrent.enable (lib.mkForce "0002");

    systemd.tmpfiles.rules = [
      ''d "${cfg.mediaDir}/Movies" 0775 jano users -''
      ''d "${cfg.mediaDir}/TV Shows" 0775 jano users -''
      ''d "${cfg.mediaDir}/Music" 0775 jano users -''
      ''d "${cfg.mediaDir}/Books" 0775 jano users -''
      ''d "${cfg.downloadDir}" 0775 jano users -''
    ];

    # Reachable over Tailscale only.
    networking.firewall.interfaces."tailscale0".allowedTCPPorts = lib.attrValues ports;
  };
}
