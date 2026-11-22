{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.deviload;
  version = "2.16.0";
  pkg = pkgs.appimageTools.wrapType2 {
    pname = "deviload";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/Pronexsteam/deviload/releases/download/v${version}/Deviload-${version}-x86_64.AppImage";
      hash = "sha256-3pAqUaZGeD5xuriu4lqehXRcUJphix1pTTk/unU/UWI=";
    };
    extraPkgs =
      p: with p; [
        ffmpeg
        yt-dlp
        deno
        gtk3
        webkitgtk_4_1
        librsvg
        libayatana-appindicator
        xdotool
        glib
        gsettings-desktop-schemas
        adwaita-icon-theme
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-base
      ];
  };
in
{
  options.programs.deviload.enable = lib.mkEnableOption "Deviload (yt-dlp GUI)";
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkg
      (pkgs.writeShellScriptBin "deviload-gpu" "export GDK_BACKEND=x11; if command -v nvidia-offload >/dev/null; then exec nvidia-offload deviload \"\$@\"; else exec deviload \"\$@\"; fi")
    ];
  };
}
