# ArtCraft launcher (Flatpak bundle shipped in this repo). Enable with modules.artcraft.enable = true.
# Installs the bundle system-wide at boot; its runtime (org.freedesktop.Platform 26.08) comes from Flathub.
# To update: replace the .flatpak file, change `bundle` below, git add, rebuild.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.artcraft;
  bundle = ./artcraft-launcher-0.13.0-linux-x86_64.flatpak;
in
{
  options.modules.artcraft.enable = lib.mkEnableOption "ArtCraft launcher (Flatpak bundle)";

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;

    systemd.services.artcraft-flatpak = {
      description = "Install ArtCraft launcher Flatpak bundle";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = [ pkgs.flatpak ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "artcraft-flatpak";
      };
      script = ''
        stamp=/var/lib/artcraft-flatpak/installed
        if [ "$(cat "$stamp" 2>/dev/null)" = "${bundle}" ]; then exit 0; fi
        flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        flatpak install --system -y --noninteractive --or-update --bundle ${bundle}
        echo "${bundle}" > "$stamp"
      '';
    };
  };
}
