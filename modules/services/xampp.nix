{ config, lib, pkgs, ... }:

let
  # Small desktop "control panel" (like the Windows XAMPP panel) built on
  # zenity. Drives the per-service systemd units below, so privileged
  # operations go through polkit (password prompt) instead of needing sudo.
  xamppPanel = pkgs.runCommand "xampp-panel" { } ''
    mkdir -p $out/bin $out/share/applications

    cat > $out/bin/xampp-panel <<'EOF'
#!/usr/bin/env bash
export PATH="${pkgs.zenity}/bin:${pkgs.systemd}/bin:${pkgs.xdg-utils}/bin:${pkgs.coreutils}/bin:${pkgs.gnused}/bin:${pkgs.gnugrep}/bin:/run/current-system/sw/bin:/bin:/usr/bin:/usr/sbin:/usr/local/bin"

while true; do
  A=$(systemctl is-active xampp-apache 2>/dev/null || echo stopped)
  M=$(systemctl is-active xampp-mysql 2>/dev/null || echo stopped)
  P=$(systemctl is-active xampp-proftpd 2>/dev/null || echo stopped)
  [ "$A" = active ] && A="RUNNING" || A="STOPPED"
  [ "$M" = active ] && M="RUNNING" || M="STOPPED"
  [ "$P" = active ] && P="RUNNING" || P="STOPPED"

  pick=$(zenity --list --title "XAMPP Control Panel" \
    --text "Apache / MySQL / ProFTPD - XAMPP 8.2.12" \
    --column "Item" --column "Status" --column "Details" --separator=$'\t' --hide-header \
    "apache" "$A" "ports 80 / 443 - http://localhost" \
    "mysql" "$M" "port 3306" \
    "proftpd" "$P" "port 21 (FTP)" \
    "phpmyadmin" "-" "manage MySQL in the browser" \
    "dashboard" "-" "XAMPP welcome page" \
    "htdocs" "-" "webroot folder (/opt/lampp/htdocs)" \
    --width 620 --height 300)
  rc=$?
  [ $rc -ne 0 ] && exit 0

  case $pick in
    apache)
      a=$(zenity --list --title "Apache" --column "Action" \
        "Start" "Stop" "Restart" "Open http://localhost" --width 240 --height 300) || exit 0
      case $a in
        Start)   systemctl start   xampp-apache ;;
        Stop)    systemctl stop    xampp-apache ;;
        Restart) systemctl restart xampp-apache ;;
        Open*)   xdg-open http://localhost ;;
      esac ;;
    mysql)
      a=$(zenity --list --title "MySQL" --column "Action" \
        "Start" "Stop" "Restart" "Open phpMyAdmin" --width 240 --height 300) || exit 0
      case $a in
        Start)   systemctl start   xampp-mysql ;;
        Stop)    systemctl stop    xampp-mysql ;;
        Restart) systemctl restart xampp-mysql ;;
        Open*)   xdg-open http://localhost/phpmyadmin ;;
      esac ;;
    proftpd)
      a=$(zenity --list --title "ProFTPD" --column "Action" \
        "Start" "Stop" "Restart" --width 240 --height 250) || exit 0
      case $a in
        Start)   systemctl start   xampp-proftpd ;;
        Stop)    systemctl stop    xampp-proftpd ;;
        Restart) systemctl restart xampp-proftpd ;;
      esac ;;
    phpmyadmin) xdg-open http://localhost/phpmyadmin ;;
    dashboard)  xdg-open http://localhost/dashboard ;;
    htdocs)     xdg-open /opt/lampp/htdocs ;;
  esac
  sleep 1
done
EOF
    chmod +x $out/bin/xampp-panel

    cat > $out/share/applications/xampp-panel.desktop <<EOF
[Desktop Entry]
Type=Application
Name=XAMPP Control Panel
Comment=Control Apache, MySQL and ProFTPD
Exec=$out/bin/xampp-panel
Icon=applications-internet
Terminal=false
Categories=Development;WebDevelopment;System;
EOF
  '';
in

{
  # XAMPP 8.2.12 installed at /opt/lampp (class workbench). NixOS has no
  # classic FHS: XAMPP's binaries expect glibc + friends under /lib64 and its
  # control scripts hard-code PATH=/sbin:/usr/sbin:/bin:/usr/bin (e.g. mysql.server
  # line 114). We provide a minimal FHS compat layer through activation scripts
  # (survives rebuilds) plus the system users XAMPP's configs reference.

  users.users.daemon = {
    uid = 1;
    group = "daemon";
    isSystemUser = true;
    description = "daemon";
    shell = "/run/current-system/sw/bin/nologin";
  };
  users.groups.daemon = { gid = 5; };

  users.users.mysql = {
    uid = 84;
    group = "mysql";
    isSystemUser = true;
    description = "MySQL server user (XAMPP)";
    shell = "/run/current-system/sw/bin/nologin";
  };
  users.groups.mysql = { gid = 84; };

  # NixOS 24.11+ replaces glibc's ld-linux with a stub that refuses to exec
  # generic FHS binaries unless nix-ld is enabled; it forwards to a real
  # loader then. Required for anything in /opt/lampp.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [ glibc.out stdenv.cc.cc.lib gcc.cc.lib ];
  };

  system.activationScripts.xamppFhs = lib.stringAfter [ "users" ] ''
    mkdir -p /bin /lib64 /sbin /usr/sbin /usr/bin /usr/local/bin

    ln -sfn ${pkgs.bash}/bin/bash /bin/bash
    ln -sfn ${pkgs.bash}/bin/bash /bin/sh
    ln -sfn ${pkgs.bash}/bin/bash /sbin/nologin

    # glibc + toolchain compat for the prebuilt /opt/lampp binaries.
    for l in ${pkgs.glibc.out}/lib/lib*.so* ${pkgs.glibc.out}/lib/ld-linux-x86-64.so.2; do
      ln -sfn "$l" /lib64/"$(basename "$l")"
    done
    ln -sfn ${pkgs.stdenv.cc.cc.lib}/lib/libstdc++.so.6 /lib64/libstdc++.so.6
    ln -sfn ${pkgs.stdenv.cc.cc.lib}/lib/libgcc_s.so.1 /lib64/libgcc_s.so.1

    # userland tools XAMPP control scripts rely on (they never see the Nix
    # store on PATH). Wholesale symlinking mirrors a real FHS distribution.
    for b in ${pkgs.coreutils}/bin/* ${pkgs.gnused}/bin/* ${pkgs.gnugrep}/bin/* \
             ${pkgs.findutils}/bin/* ${pkgs.diffutils}/bin/* ${pkgs.gzip}/bin/* \
             ${pkgs.gnutar}/bin/* ${pkgs.gawk}/bin/* ${pkgs.procps}/bin/* \
             ${pkgs.net-tools}/bin/* ${pkgs.bc}/bin/*; do
      [ -f "$b" ] && ln -sfn "$b" /bin/"$(basename "$b")" || true
    done
    ln -sfn ${pkgs.glibc.bin}/bin/getent /usr/bin/getent

    # Data owned by the users declared above.
    chown -R mysql:mysql /opt/lampp/var/mysql 2>/dev/null || true
    chown -R jano:users /opt/lampp/htdocs 2>/dev/null || true
    chown daemon:daemon /opt/lampp/temp 2>/dev/null || true
    chmod 770 /opt/lampp/temp 2>/dev/null || true
  '';

  # Per-service units so the control panel can manage each daemon via
  # systemctl (polkit prompts for jano's password). mysqld is stopped with
  # mysqladmin because mysql.server's SIGTERM path is defeated by mysqld_safe
  # crash-protection restarting the daemon.
  systemd.services.xampp-apache = {
    description = "XAMPP Apache";
    after = [ "network.target" ];
    wants = [ "xampp-mysql.service" ];
    environment.PATH = lib.mkForce "/run/current-system/sw/bin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/sbin";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "/bin/sh /opt/lampp/xampp startapache";
      ExecStop = "/bin/sh /opt/lampp/xampp stopapache";
    };
  };

  systemd.services.xampp-mysql = {
    description = "XAMPP MariaDB";
    after = [ "network.target" ];
    environment.PATH = lib.mkForce "/run/current-system/sw/bin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/sbin";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "/bin/sh /opt/lampp/xampp startmysql";
      ExecStop = "/opt/lampp/bin/mysqladmin -u root shutdown";
    };
  };

  systemd.services.xampp-proftpd = {
    description = "XAMPP ProFTPD";
    after = [ "network.target" ];
    environment.PATH = lib.mkForce "/run/current-system/sw/bin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/sbin";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "/bin/sh /opt/lampp/xampp startftp";
      ExecStop = "/bin/sh /opt/lampp/xampp stopftp";
    };
  };

  systemd.targets.xampp = {
    description = "XAMPP (Apache + MySQL + ProFTPD)";
    wants = [
      "xampp-apache.service"
      "xampp-mysql.service"
      "xampp-proftpd.service"
    ];
    wantedBy = [ "multi-user.target" ];
  };

  environment.systemPackages = [
    xamppPanel
    pkgs.zenity
    pkgs.xdg-utils
  ];
}