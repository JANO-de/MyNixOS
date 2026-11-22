# IT-Tools: static developer toolbox served by Caddy at https://\<host\>:18090 (tailnet only).
{ ... }:
{
  flake.nixosModules.server-it-tools =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.modules.services.itTools;
      host = "desktop.tailc8366c.ts.net";
      port = 18090;
    in
    {
      options.modules.services.itTools.enable = lib.mkEnableOption "IT-Tools";

      config = lib.mkIf cfg.enable {
        services.caddy.enable = true;
        services.caddy.virtualHosts."${host}:${toString port}".extraConfig = ''
          root * ${pkgs.it-tools}/lib
          try_files {path} /index.html
          file_server
        '';
        networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ port ];
      };
    };
}
