# Media tracker: scans /mnt/storage/media (Movies, TV Shows, Music, Books), reads file
# metadata (ffprobe, EPUB/PDF/ComicInfo) and registers new content in an .xlsx tracker
# as OnServer. Triggered by path watchers on the library folders + a periodic timer.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.services.mediaTracker;

  py = pkgs.python3.withPackages (ps: [ ps.openpyxl ]);

  script = pkgs.writeShellScript "media-tracker" ''
    export PATH=${lib.makeBinPath [ pkgs.ffmpeg-headless pkgs.poppler-utils ]}:$PATH
    export MEDIA_DIR=${lib.escapeShellArg cfg.mediaDir}
    export TRACKER_FILE=${lib.escapeShellArg cfg.trackerFile}
    export STATE_FILE=/var/lib/media-tracker/state.json
    export SETTLE_SECONDS=${toString cfg.settleSeconds}
    export DIR_MOVIES=${lib.escapeShellArg cfg.folders.movies}
    export DIR_SHOWS=${lib.escapeShellArg cfg.folders.shows}
    export DIR_MUSIC=${lib.escapeShellArg cfg.folders.music}
    export DIR_BOOKS=${lib.escapeShellArg cfg.folders.books}
    exec ${py}/bin/python3 ${./tracker.py}
  '';

  # systemd path unit names can't contain spaces, so use fixed names.
  watched = {
    movies = cfg.folders.movies;
    shows = cfg.folders.shows;
    music = cfg.folders.music;
    books = cfg.folders.books;
  };
in
{
  options.modules.services.mediaTracker = {
    enable = lib.mkEnableOption "media tracker (registers new files from the media library in an xlsx)";

    mediaDir = lib.mkOption {
      type = lib.types.path;
      default = config.modules.services.jellyfin.mediaDir;
      description = "Root of the media library.";
    };

    trackerFile = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/storage/tracker/server-tracker.xlsx";
      description = "Spreadsheet to update (created if missing). Keep it outside the media dir.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "jano";
      description = "User the scan runs as (owns the xlsx).";
    };

    folders = {
      movies = lib.mkOption { type = lib.types.str; default = "Movies"; };
      shows = lib.mkOption { type = lib.types.str; default = "TV Shows"; };
      music = lib.mkOption { type = lib.types.str; default = "Music"; };
      books = lib.mkOption { type = lib.types.str; default = "Books"; };
    };

    settleSeconds = lib.mkOption {
      type = lib.types.int;
      default = 120;
      description = "Ignore files modified more recently than this (unfinished downloads).";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "15min";
      description = "Fallback periodic scan (catches changes deeper than the watched folders).";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${builtins.dirOf cfg.trackerFile} 0775 ${cfg.user} users -"
    ];

    systemd.services.media-tracker = {
      description = "Register new media files in the tracker spreadsheet";
      after = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        ExecStart = script;
        StateDirectory = "media-tracker";
        Nice = 19;
        IOSchedulingClass = "idle";
        # Hardening: read-only media, write only the tracker dir + state.
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        ReadOnlyPaths = [ cfg.mediaDir ];
        ReadWritePaths = [ (builtins.dirOf cfg.trackerFile) ];
      };
    };

    # Fires when something is added/removed directly inside a library folder.
    systemd.paths = lib.mapAttrs' (
      name: folder:
      lib.nameValuePair "media-tracker-${name}" {
        wantedBy = [ "multi-user.target" ];
        pathConfig = {
          PathChanged = "${cfg.mediaDir}/${folder}";
          Unit = "media-tracker.service";
          TriggerLimitIntervalSec = "60s";
          TriggerLimitBurst = 1;
        };
      }
    ) watched;

    systemd.timers.media-tracker = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = cfg.interval;
        Persistent = true;
      };
    };
  };
}
