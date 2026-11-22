# Homepage: one dashboard listing the services hosted on this machine.
# Widget secrets (API keys) live in /var/lib/homepage-secrets.env, NOT in the repo.
{ config, lib, ... }:

let
  cfg = config.modules.services.homepage;
  host = "desktop.tailc8366c.ts.net";
  local = "http://localhost";
  secretsFile = "/var/lib/homepage-secrets.env";

  # Weather widget coordinates: change to your city.
  latitude = 36.13;
  longitude = -5.45;

  # Link + live status dot for a service.
  svc = name: attrs: { ${name} = attrs; };
in
{
  options.modules.services.homepage.enable =
    lib.mkEnableOption "Homepage dashboard on :8080 (reachable over Tailscale)";

  config = lib.mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;
      listenPort = 8080;
      # Homepage rejects requests whose Host header isn't listed here.
      allowedHosts = "${host},${host}:8080,localhost:8080,127.0.0.1:8080,dash.home.arpa";
      environmentFiles = [ secretsFile ];

      # Gradient only shows if the background image can't load (offline).
      customCSS = ''
        body {
          background: linear-gradient(160deg, #1c1c1f 0%, #0f0f11 100%) fixed;
        }
      '';

      settings = {
        title = "Desktop";
        headerStyle = "boxedWidgets"; # clean | boxed | underlined | boxedWidgets
        theme = "dark";
        color = "slate"; # neutral; try zinc, stone, neutral or gray
        cardBlur = "xl"; # sm | md | lg | xl
        background = {
          image = "https://images.unsplash.com/photo-1502790671504-542ad42d5189?w=2560&auto=format&fit=crop&q=80";
          blur = "sm";
          saturate = 100;
          brightness = 50;
          opacity = 100;
        };
        target = "_blank";
        statusStyle = "dot"; # dot | basic
        showStats = true;
        useEqualHeights = true;
        hideVersion = true;
        iconStyle = "theme";
        fiveColumns = false;
        quicklaunch = {
          searchDescriptions = true;
          hideInternetSearch = false;
          showSearchSuggestions = true;
        };
        layout = {
          "Media" = {
            header = true;
            style = "row";
            columns = 2;
            icon = "mdi-play-circle-outline";
          };
          "Automation" = {
            header = true;
            style = "row";
            columns = 4;
            icon = "mdi-robot-outline";
          };
          "AI" = {
            header = true;
            style = "row";
            columns = 2;
            icon = "mdi-brain";
          };
          "System" = {
            header = true;
            style = "row";
            columns = 2;
            icon = "mdi-server";
          };
          "Dev" = {
            header = true;
            style = "row";
            columns = 4;
            icon = "mdi-code-braces";
          };
        };
      };

      services = [
        {
          "Media" = [
            (svc "Jellyfin" {
              href = "http://jellyfin.home.arpa";
              description = "Watch movies, shows and music";
              icon = "jellyfin.png";
              siteMonitor = "${local}:8096";
              widget = {
                type = "jellyfin";
                url = "${local}:8096";
                key = "{{HOMEPAGE_VAR_JELLYFIN_KEY}}";
                enableBlocks = true;
                enableNowPlaying = true;
                enableUser = true;
                showEpisodeNumber = true;
              };
            })
            (svc "Jellyseerr" {
              href = "http://seerr.home.arpa";
              description = "Request movies and shows";
              icon = "jellyseerr.png";
              siteMonitor = "${local}:5055";
              widget = {
                type = "jellyseerr";
                url = "${local}:5055";
                key = "{{HOMEPAGE_VAR_JELLYSEERR_KEY}}";
              };
            })
            (svc "FreshRSS" {
              href = "https://${host}:18087";
              description = "RSS reader";
              icon = "freshrss.png";
              siteMonitor = "https://${host}:18087";
            })
            (svc "Kapowarr" {
              href = "https://${host}:15656";
              description = "Comics downloader";
              icon = "kapowarr.png";
              siteMonitor = "${local}:5656";
            })
            (svc "Shelfmark" {
              href = "https://${host}:18084";
              description = "Search and download books";
              icon = "shelfmark.png";
              siteMonitor = "${local}:8084";
            })
            (svc "Kavita" {
              href = "http://kavita.home.arpa";
              description = "Books, comics and manga";
              icon = "kavita.png";
              siteMonitor = "${local}:5000";
            })
            (svc "Navidrome" {
              href = "http://navidrome.home.arpa";
              description = "Music streaming (Subsonic)";
              icon = "navidrome.png";
              siteMonitor = "${local}:4533";
            })
          ];
        }
        {
          "Automation" = [
            (svc "Sonarr" {
              href = "http://100.116.102.50:8989";
              description = "TV shows and anime";
              icon = "sonarr.png";
              siteMonitor = "${local}:8989";
              widget = {
                type = "sonarr";
                url = "${local}:8989";
                key = "{{HOMEPAGE_VAR_SONARR_KEY}}";
                enableQueue = true;
              };
            })
            (svc "Radarr" {
              href = "http://100.116.102.50:7878";
              description = "Movies";
              icon = "radarr.png";
              siteMonitor = "${local}:7878";
              widget = {
                type = "radarr";
                url = "${local}:7878";
                key = "{{HOMEPAGE_VAR_RADARR_KEY}}";
                enableQueue = true;
              };
            })
            (svc "Prowlarr" {
              href = "http://100.116.102.50:9696";
              description = "Indexers";
              icon = "prowlarr.png";
              siteMonitor = "${local}:9696";
              widget = {
                type = "prowlarr";
                url = "${local}:9696";
                key = "{{HOMEPAGE_VAR_PROWLARR_KEY}}";
              };
            })
            (svc "Lidarr" {
              href = "http://100.116.102.50:8686";
              description = "Music";
              icon = "lidarr.png";
              siteMonitor = "${local}:8686";
            })
            (svc "Bazarr" {
              href = "http://100.116.102.50:6767";
              description = "Subtitles";
              icon = "bazarr.png";
              siteMonitor = "${local}:6767";
            })
            (svc "qBittorrent" {
              href = "http://100.116.102.50:8112";
              description = "Downloads";
              icon = "qbittorrent.png";
              siteMonitor = "${local}:8112";
              widget = {
                type = "qbittorrent";
                url = "${local}:8112";
                key = "{{HOMEPAGE_VAR_QBIT_KEY}}";
              };
            })
            (svc "Calendar" {
              description = "Upcoming episodes and movies";
              icon = "mdi-calendar";
              widget = {
                type = "calendar";
                firstDayInWeek = "monday";
                view = "monthly";
                maxEvents = 10;
                integrations = [
                  {
                    type = "sonarr";
                    service_group = "Automation";
                    service_name = "Sonarr";
                  }
                  {
                    type = "radarr";
                    service_group = "Automation";
                    service_name = "Radarr";
                  }
                ];
              };
            })
          ];
        }
        {
          "AI" = [
            (svc "llama.cpp" {
              href = "http://100.116.102.50:8081";
              description = "Local LLM server";
              icon = "mdi-brain";
              siteMonitor = "${local}:8081";
            })
            (svc "Open WebUI" {
              href = "http://chat.home.arpa";
              description = "Chat with the local models";
              icon = "open-webui.png";
              siteMonitor = "${local}:8082";
            })
          ];
        }
        {
          "System" = [
            (svc "Sunshine" {
              href = "https://${host}:47990";
              description = "Game/desktop streaming (self-signed cert)";
              icon = "sunshine.png";
            })
            (svc "Stirling PDF" {
              href = "https://${host}:18085";
              description = "PDF tools";
              icon = "stirling-pdf.png";
              siteMonitor = "${local}:8085";
            })
            (svc "IT-Tools" {
              href = "https://${host}:18090";
              description = "Developer toolbox";
              icon = "it-tools.png";
            })
            (svc "Uptime Kuma" {
              href = "http://uptime.home.arpa";
              description = "Service monitoring and alerts";
              icon = "uptime-kuma.png";
              siteMonitor = "${local}:3001";
            })
            (svc "Vikunja" {
              href = "http://todo.home.arpa";
              description = "To-do lists and tasks";
              icon = "vikunja.png";
              siteMonitor = "${local}:3456";
            })
            (svc "Tailscale" {
              href = "https://login.tailscale.com/admin/machines";
              description = "Tailnet machines";
              icon = "tailscale.png";
            })
          ];
        }
      ];

      bookmarks = [
        {
          "Dev" = [
            (svc "Stirling PDF" [
              {
                abbr = "SP";
                href = "https://${host}:18085";
              }
            ])
            (svc "GitHub" [
              {
                abbr = "GH";
                href = "https://github.com";
              }
            ])
            (svc "NixOS Search" [
              {
                abbr = "NS";
                href = "https://search.nixos.org";
              }
            ])
            (svc "Home Manager" [
              {
                abbr = "HM";
                href = "https://home-manager-options.extranix.com";
              }
            ])
            (svc "NixOS Wiki" [
              {
                abbr = "NW";
                href = "https://wiki.nixos.org";
              }
            ])
            (svc "Torrent Claw" [
              {
                abbr = "TC";
                href = "https://torrentclaw.com/es";
              }
            ])
          ];
        }
      ];

      widgets = [
        {
          greeting = {
            text_size = "xl";
            text = "Hello, jano";
          };
        }
        {
          datetime = {
            text_size = "xl";
            format = {
              timeStyle = "short";
              dateStyle = "medium";
              hourCycle = "h23";
            };
          };
        }
        {
          resources = {
            label = "System";
            cpu = true;
            memory = true;
            cputemp = true;
            uptime = true;
            disk = "/";
          };
        }
        {
          resources = {
            label = "Storage";
            disk = "/mnt/storage";
          };
        }
        {
          openmeteo = {
            label = "Weather";
            inherit latitude longitude;
            units = "metric";
            cache = 10;
          };
        }
        {
          search = {
            provider = "duckduckgo";
            focus = false;
            showSearchSuggestions = true;
            target = "_blank";
          };
        }
      ];
    };

    # Secrets file must exist or the service won't start; create it empty if missing.
    systemd.tmpfiles.rules = [ "f ${secretsFile} 0600 root root -" ];

    # Dashboard reachable from the tailnet only.
    networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
      8080
      # 8081 # llama.cpp, if you want its link to work from your phone
    ];
  };
}
