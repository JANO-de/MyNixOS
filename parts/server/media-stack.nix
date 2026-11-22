# Media automation: Prowlarr (indexers) -> Sonarr/Radarr/Lidarr (library) -> qBittorrent (downloads)
# -> /mnt/storage/media (Jellyfin), plus Jellyseerr (request page) and Bazarr (subtitles).
# Web UIs are only opened on the tailscale0 interface.
{ ... }:
{
  flake.nixosModules.server-media-stack =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.modules.services.mediaStack;
      ports = {
        sonarr = 8989;
        radarr = 7878;
        prowlarr = 9696;
        lidarr = 8686;
        bazarr = 6767;
        jellyseerr = 5055;
        qbittorrent = 8112; # not 8080: Homepage uses it
      };
    in
    {
      options.modules.services.mediaStack = {
        enable = lib.mkEnableOption "Sonarr, Radarr, Lidarr, Bazarr, Prowlarr, qBittorrent and Jellyseerr";

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
        services.lidarr = {
          enable = true;
          group = "users";
        };
        # Bazarr writes .srt files next to the media, so it needs the shared group too.
        services.bazarr = {
          enable = true;
          group = "users";
          listenPort = ports.bazarr;
        };
        services.seerr.enable = true; # renamed from services.jellyseerr

        services.qbittorrent = lib.mkIf cfg.qbittorrent.enable {
          enable = true;
          group = "users";
          webuiPort = ports.qbittorrent;
          serverConfig.Preferences.WebUI = {
            LocalHostAuth = false;
            AuthSubnetWhitelistEnabled = true;
            AuthSubnetWhitelist = "172.16.0.0/12";
            HostHeaderValidation = false;
            CSRFProtection = false;
          };
          serverConfig.BitTorrent."Session\\GlobalMaxRatio" = "0.01";
        };

        environment.systemPackages = [
          (pkgs.writeShellScriptBin "magnet-add" ''
            ${pkgs.curl}/bin/curl -s -F "urls=$1" \
              http://127.0.0.1:${toString ports.qbittorrent}/api/v2/torrents/add
          '')
          (pkgs.makeDesktopItem {
            name = "magnet-add";
            desktopName = "Add magnet to qBittorrent";
            exec = "magnet-add %u";
            mimeTypes = [ "x-scheme-handler/magnet" ];
            noDisplay = true;
          })
        ];

        xdg.mime.defaultApplications."x-scheme-handler/magnet" = "magnet-add.desktop";

        # Group-writable files so jano can still manage what the apps create.
        systemd.services.sonarr.serviceConfig.UMask = lib.mkForce "0002";
        systemd.services.radarr.serviceConfig.UMask = lib.mkForce "0002";
        systemd.services.lidarr.serviceConfig.UMask = lib.mkForce "0002";
        systemd.services.bazarr.serviceConfig.UMask = lib.mkForce "0002";
        systemd.services.qbittorrent.serviceConfig.UMask = lib.mkIf cfg.qbittorrent.enable (
          lib.mkForce "0002"
        );

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
    };
}
