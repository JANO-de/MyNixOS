# Odysseus AI host support: Docker, plus llama.cpp reachable from containers.
{ config, lib, ... }:

let
  cfg = config.modules.services.odysseus;
in
{
  options.modules.services.odysseus.enable =
    lib.mkEnableOption "Docker for Odysseus AI (compose app lives in ~/odysseus; reaches host llama.cpp on :8080)";

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;
    virtualisation.docker.daemon.settings = {
      dns = [ "8.8.8.8" "1.1.1.1" ];
    };
    users.users.jano.extraGroups = [ "docker" ];

    # Containers can't reach loopback; bind wider, open :8080 only to Docker subnets.
    services.llama-cpp.host = "0.0.0.0";
    networking.firewall.extraCommands = ''
      iptables -A nixos-fw -p tcp -s 172.16.0.0/12 --dport 8081 -j nixos-fw-accept
    '';
  };
}