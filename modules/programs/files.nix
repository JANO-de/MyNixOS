# File management: Nautilus (default for folders), Yazi and its previewers, archive tools, gvfs.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.programs.files;
in
{
  options.modules.programs.files.enable = lib.mkEnableOption "file managers and archive tools";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nautilus
      yazi
      chafa
      ffmpegthumbnailer
      poppler-utils
      p7zip
      unzip
    ];

    services.gvfs.enable = true;

    xdg.mime.defaultApplications = {
      "inode/directory" = "org.gnome.Nautilus.desktop";
      "application/x-gnome-saved-search" = "org.gnome.Nautilus.desktop";
    };
  };
}
