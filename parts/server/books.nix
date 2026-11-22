# Kapowarr (comics) + Shelfmark (books), Docker, localhost only; HTTPS via Caddy (tailnet only).
#   Kapowarr  https://\<host\>:15656 -> <mediaDir>/Comics
#   Shelfmark https://\<host\>:18084 -> <mediaDir>/Books
{ ... }:
{
  flake.nixosModules.server-books =
    { config, lib, ... }:

    let
      cfg = config.modules.services.books;
      host = "desktop.tailc8366c.ts.net";
      media = config.modules.services.jellyfin.mediaDir;
    in
    {
      options.modules.services.books.enable = lib.mkEnableOption "Kapowarr and Shelfmark";

      config = lib.mkIf cfg.enable {
        virtualisation.docker.enable = true;
        virtualisation.oci-containers.backend = "docker";

        virtualisation.oci-containers.containers = {
          kapowarr = {
            image = "mrcas/kapowarr:latest";
            ports = [ "127.0.0.1:5656:5656" ];
            volumes = [
              "/var/lib/kapowarr:/app/db"
              "/mnt/storage/downloads/kapowarr:/app/temp_downloads"
              "${media}/Comics:/comics-1"
              "${media}/Manga:/manga-1"
            ];
          };
          warp = {
            image = "caomingjun/warp:latest";
            ports = [ "172.17.0.1:1080:1080" ];
            extraOptions = [
              "--cap-add=NET_ADMIN"
              "--device=/dev/net/tun"
              "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
            ];
            volumes = [ "/var/lib/warp:/var/lib/cloudflare-warp" ];
          };
          shelfmark = {
            image = "ghcr.io/calibrain/shelfmark:latest";
            ports = [ "127.0.0.1:8084:8084" ];
            environment = {
              PUID = "1000"; # jano
              PGID = "100"; # users
            };
            volumes = [
              "/var/lib/shelfmark:/config"
              "${media}/Books:/books"
            ];
          };
        };

        systemd.tmpfiles.rules = [
          "d /var/lib/kapowarr 0755 root root -"
          "d /var/lib/shelfmark 0755 jano users -"
          "d /mnt/storage/downloads/kapowarr 0775 root users -"
          ''d "${media}/Comics" 0775 jano users -''
          ''d "${media}/Manga" 0775 jano users -''
        ];

        services.caddy.enable = true;
        services.caddy.virtualHosts."${host}:15656".extraConfig = "reverse_proxy 127.0.0.1:5656";
        services.caddy.virtualHosts."${host}:18084".extraConfig = "reverse_proxy 127.0.0.1:8084";
        networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
          15656
          18084
        ];
        networking.firewall.interfaces."docker0".allowedTCPPorts = [
          8989
          7878
          9696
          8686
          6767
          5055
          8112
          1080
        ];
      };
    };
}
