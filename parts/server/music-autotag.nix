# Auto-tag new music: beets (MusicBrainz tags + cover art + genres) triggered by a
# recursive inotify watcher on the Music folder. Tags are written in place; files are
# never moved or renamed. Albums beets is not confident about are skipped (quiet mode).
_: {
  flake.nixosModules.server-music-autotag =
    { pkgs, ... }:
    let
      musicDir = "/mnt/storage/media/Music";
      beetsDir = "/var/lib/beets";

      beetsConfig = pkgs.writeText "beets-config.yaml" ''
        directory: ${musicDir}
        plugins: musicbrainz chroma fetchart embedart lastgenre
        import:
          copy: no
          move: no
          write: yes
          incremental: yes
          quiet: yes
          quiet_fallback: skip
          group_albums: yes
          log: ${beetsDir}/import.log
        match:
          strong_rec_thresh: 0.20
          max_rec:
            missing_tracks: strong
        fetchart:
          auto: yes
          minwidth: 500
        embedart:
          remove_art_file: yes
          auto: yes
        lastgenre:
          auto: yes
          source: album
      '';

      watcher = pkgs.writeShellApplication {
        name = "music-autotag";
        runtimeInputs = [
          pkgs.beets
          pkgs.chromaprint
          pkgs.inotify-tools
          pkgs.coreutils
        ];
        text = ''
          export BEETSDIR=${beetsDir}
          install -Dm644 ${beetsConfig} "$BEETSDIR/config.yaml"
          while true; do
            beet import -q "${musicDir}" || true
            # wait for a change (or re-check hourly), then let copies finish
            timeout 3600 inotifywait -r -q -e close_write -e moved_to -e create "${musicDir}" >/dev/null || true
            sleep 120
          done
        '';
      };
    in
    {
      environment.systemPackages = [ pkgs.beets ];

      systemd.services.music-autotag = {
        description = "Auto-tag new music with beets";
        wantedBy = [ "multi-user.target" ];
        unitConfig.RequiresMountsFor = musicDir;
        serviceConfig = {
          ExecStart = "${watcher}/bin/music-autotag";
          User = "jano";
          Group = "users";
          StateDirectory = "beets";
          Restart = "on-failure";
          RestartSec = 30;
          Nice = 10;
          IOSchedulingClass = "idle";
        };
      };
    };
}
