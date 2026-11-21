# Navidrome: music server (Subsonic API), serves /mnt/storage/media/Music on :4533
{ ... }:
{
  services.navidrome = {
    enable = true;
    group = "users"; # media is jano:users, 0775
    openFirewall = true; # remove if Caddy fronts it
    settings = {
      MusicFolder = "/mnt/storage/media/Music";
      Address = "0.0.0.0"; # use "127.0.0.1" behind Caddy
      Port = 4533;
    };
  };
}
