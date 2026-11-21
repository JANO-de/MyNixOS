# Kavita: reader/server for the Books folder (ebooks, PDFs, comics, manga).
# Reachable over Tailscale (http :5000, https :15000 via caddy.nix).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.services.kavita;
  tokenFile = "/var/lib/kavita-token";
in
{
  options.modules.services.kavita = {
    enable = lib.mkEnableOption "Kavita book, comic and manga server";

    port = lib.mkOption {
      type = lib.types.port;
      default = 5000;
      description = "HTTP port Kavita listens on.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.kavita = {
      enable = true;
      tokenKeyFile = tokenFile;
      settings.Port = cfg.port;
    };

    # Kavita needs a random signing key on disk. Create it once, outside the repo.
    systemd.services.kavita-token = {
      description = "Generate the Kavita token key";
      requiredBy = [ "kavita.service" ];
      before = [ "kavita.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        if [ ! -s ${tokenFile} ]; then
          ${pkgs.openssl}/bin/openssl rand -base64 96 | tr -d '\n' > ${tokenFile}
        fi
        chown kavita:kavita ${tokenFile}
        chmod 600 ${tokenFile}
      '';
    };

    # Read the library (/mnt/storage/media/Books is jano:users, 0775).
    users.users.kavita.extraGroups = [ "users" ];

    networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ cfg.port ];
  };
}
