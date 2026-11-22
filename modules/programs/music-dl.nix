# music-dl: download music as real audio with tags + cover, into Artist/Album/ folders
{ pkgs, ... }:
let
  musicDir = "/mnt/storage/media/Music";
  musicDl = pkgs.writeShellApplication {
    name = "music-dl";
    runtimeInputs = [
      pkgs.yt-dlp
      pkgs.ffmpeg
    ];
    text = ''
      if [ "$#" -eq 0 ]; then
        echo "Usage: music-dl <music.youtube.com album/playlist URL> [more URLs]"
        exit 1
      fi
      yt-dlp -x --audio-format mp3 --audio-quality 0 \
        --embed-metadata --embed-thumbnail --convert-thumbnails jpg \
        -o "${musicDir}/%(album_artist,artist,uploader)s/%(album,playlist_title)s/%(title)s.%(ext)s" \
        "$@"
    '';
  };
in
{
  environment.systemPackages = [ musicDl ];
  environment.shellAliases.mdl = "music-dl";
}
