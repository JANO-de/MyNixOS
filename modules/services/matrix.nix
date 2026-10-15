{ config, pkgs, lib, ... }:
let
  fqdn    = "desktop.tailc8366c.ts.net";
  certDir = "/var/lib/tailscale-certs";
in {
  nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];

  systemd.services.tailscale-cert-renew = {
    description = "Renew Tailscale TLS cert";
    after    = [ "tailscaled.service" "network-online.target" ];
    wants    = [ "network-online.target" ];
    requires = [ "tailscaled.service" ];
    serviceConfig = {
      Type      = "oneshot";
      ExecStart = pkgs.writeShellScript "tailscale-cert" ''
        set -euo pipefail
        mkdir -p ${certDir}
        ${pkgs.tailscale}/bin/tailscale cert \
          --cert-file ${certDir}/cert.pem \
          --key-file  ${certDir}/key.pem \
          ${fqdn}
        chown root:nginx ${certDir}/key.pem
        chmod 640 ${certDir}/key.pem
      '';
    };
  };
  systemd.timers.tailscale-cert-renew = {
    wantedBy    = [ "timers.target" ];
    timerConfig = { OnCalendar = "daily"; Persistent = true; };
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings   = true;
    recommendedProxySettings = true;
    recommendedGzipSettings  = true;
    virtualHosts."${fqdn}" = {
      forceSSL          = true;
      sslCertificate    = "${certDir}/cert.pem";
      sslCertificateKey = "${certDir}/key.pem";
      listen = [
        { addr = "0.0.0.0"; port = 8448; ssl = true; }
      ];
      locations."~ ^(/_matrix|/_synapse/client)" = {
        proxyPass   = "http://127.0.0.1:8008";
        extraConfig = "client_max_body_size 50M;";
      };
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "matrix-synapse" "mautrix-whatsapp" ];
    ensureUsers = [
      { name = "matrix-synapse";   ensureDBOwnership = true; }
      { name = "mautrix-whatsapp"; ensureDBOwnership = true; }
    ];
  };

  services.matrix-synapse = {
    enable = true;
    settings = {
      server_name    = fqdn;
      public_baseurl = "https://${fqdn}:8448";
      listeners = [{
        port           = 8008;
        bind_addresses = [ "127.0.0.1" ];
        type           = "http";
        tls            = false;
        x_forwarded    = true;
        resources      = [{ names = [ "client" "federation" ]; compress = false; }];
      }];
      database = {
        name = "psycopg2";
        args = {
          user     = "matrix-synapse";
          database = "matrix-synapse";
          host     = "/run/postgresql";
        };
      };
      enable_registration                = false;
      allow_public_rooms_over_federation = false;
    };
    extraConfigFiles = [ "/var/lib/matrix-synapse/secrets.yaml" ];
  };

  services.mautrix-whatsapp = {
    enable = true;
    settings = {
      homeserver = {
        address = "http://127.0.0.1:8008";
        domain  = fqdn;
      };
      appservice = {
        hostname = "127.0.0.1";
        port     = 29318;
      };
      bridge.permissions."@jano:${fqdn}" = "admin";
      database = {
        type = "postgres";
        uri  = "postgres:///mautrix-whatsapp?host=/run/postgresql";
      };
    };
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 8448 ];
}
