# Aula_1CFGS: internet only via a Squid proxy, and it must not take the default route.
# 192.168.8.1 answers DHCP/DNS but forwards nothing; the only way out is the
# proxy on :8080 (3128 returns ERR_ACCESS_DENIED). The dispatcher below sets
# proxy vars for the session while that network is active (NetworkManager here
# cannot store the proxy setting itself). The profile (with PSK) lives in
# /etc/NetworkManager/system-connections, unmanaged by NixOS, and must have
# ipv4.never-default so the dead uplink doesn't win over the USB ethernet.
{ pkgs, ... }:

{
  environment.etc."NetworkManager/dispatcher.d/10-aula-proxy" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      # $1 = interface, $2 = action; the connection id arrives as CONNECTION_ID.
      [ "$2" = "up" ] || [ "$2" = "down" ] || exit 0
      [ "$CONNECTION_ID" = "Aula_1CFGS" ] || exit 0

      # Squid is on this subnet: exempt it so the proxy call isn't proxied.
      no_proxy="localhost,127.0.0.1,::1,192.168.0.0/16,.local"
      export no_proxy NO_PROXY="$no_proxy"
      proxy="http://192.168.8.1:8080"

      # Dispatcher has a near-empty PATH: use store paths for every command.
      # list-sessions columns: SESSION UID USER SEAT LEADER CLASS -> UID=$2, CLASS=$6.
      uid=$(${pkgs.systemd}/bin/loginctl list-sessions --no-legend 2>/dev/null \
        | ${pkgs.gawk}/bin/awk '$6 == "user" && $2 ~ /^[0-9]+$/ { print $2; exit }')
      [ -n "$uid" ] || exit 0
      runtime="/run/user/$uid"
      [ -d "$runtime" ] || exit 0
      target="$runtime/aula-proxy.env"

      if [ "$2" = "up" ]; then
        printf '%s\n' \
          "export http_proxy=$proxy https_proxy=$proxy HTTP_PROXY=$proxy HTTPS_PROXY=$proxy no_proxy=$no_proxy NO_PROXY=$no_proxy" \
          > "$target.new"
        chown "$uid" "$target.new"
        chmod 600 "$target.new"
        mv "$target.new" "$target"
      else
        # Leaving the network takes the proxy with it.
        rm -f "$target"
      fi
    '';
  };
}
